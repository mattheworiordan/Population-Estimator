require 'image_size'

##
# ImportGmapTiles uses proxy servers to retrieve all the Google Map tile images from their servers
#
# As Google restricts google map queries to around 1,000 per day, the use of public proxies is required
# Fortunately, the public proxies for some reason mostly use the same URL conventions so a simple wget
# post request can be constructed which works for more than half of all public proxies! (as of Jan 2010)
#
# Lets hope the public proxies don't mind us using them for this :O
#
class ImportGmapTiles
  def initialize()
    @zoom_range = (AppConfig.gmap_min_zoom..AppConfig.gmap_max_zoom).to_a
    @pause_after = 20
    @pause_for_seconds = 2

    # uses proxy list from here http://www.publicproxyservers.com/proxy/list_avr_time1.html
    #   test with this URL directly hitting Google http://mt2.google.com/vt/x=125&y=86&z=8
    #   test using proxy and wget as follows
    #     wget http://www.unblocktwitter.org/includes/process.php?action=update --post-data=u=http%3A%2F%2Fmt2.google.com%2Fvt%2Fx%3D125%26y%3D86%26z%3D8 --output-document=gmap_tile.png

    # build up list of supported proxy methods
    @proxy_methods = [
      { :url => "/index.php", :post_data => "q={URL}&hl%5Binclude_form%5D=on&hl%5Baccept_cookies%5D=on&hl%5Bshow_images%5D=on&hl%5Bshow_referer%5D=on&hl%5Bbase64_encode%5D=on&hl%5Bstrip_meta%5D=on&hl%5Bsession_cookies%5D=on"},
      { :url => "/includes/process.php?action=update", :post_data => "u={URL}"},
    ]

    @proxy_index = 0
    @proxy_failure_max = 3 * @proxy_methods.length # we try X times for each proxy_method
    @proxies = []

    # build up list of all proxy servers across 10 pages based on the ones with the best response times
    SLogger.info "Getting list of proxies" do
      proxy_list_urls = ( (1..10).map { |id| "http://www.publicproxyservers.com/proxy/list_avr_time#{id}.html" } )
      proxy_list_urls.each do |proxy|
        # parse the HTML and put the links into proxies without trailing /
        Nokogiri::HTML.parse( open( proxy ) ).css("td.pthtdd a").each { |link| @proxies << link['href'].gsub(/\/+$/, ""); }
      end
    end

    # remove duplicates and put in alph order (pretty!)
    @proxies = @proxies.uniq.sort

    SLogger.info "Unique proxies found #{@proxies.count}\n\n#{@proxies.join(',')}"
  end

  ##
  # Start importing all Google Map tiles which we don't have locally in the db path
  #
  def start(*options)
    # prepare proxy_list object which keeps track of successful and failed request for Gmap tiles
    @proxy_list = @proxies.map { |proxy_url| { :url => proxy_url, :success => 0, :failures => 0 } }

    tiles = []
    @zoom_range.each do |zoom|
      # build up array of arrays for all tile combos in structure [x,y,zoom]
      # i.e. for zoom 1 we have a range of 0-1 in x & y dimension
      # so array is built up as 0,0,1, 0,1,1, 1,0,1, 1,1,1
      tiles.concat( ( (0...2**zoom).to_a*(2**zoom) ).zip( ( (0...2**zoom).to_a*(2**zoom) ).sort, [zoom] * 4**zoom) )
    end

    SLogger.info "Zoom range including #{@zoom_range.to_a.join(',')} requires #{tiles.length} tiles"

    successful = skipped = failed = 0

    tiles.each do |tile|
      # get vars to use for the tile
      x,y,zoom = tile

      while ( !all_proxies_failed? )
        result = download_tile(x,y,zoom)
        successful, skipped, failed = result.successful+successful, result.skipped+skipped, result.failed+failed
        log_to_proxy_download_success if result.successful == 1
        log_to_proxy_download_failed if result.failed == 1

        if ( (successful+1) % @pause_after == 0 )
          SLogger.info "---- Processed #{successful+skipped+failed}/#{tiles.count} tiles: #{successful} successful, #{skipped} skipped, #{failed} failed.  Pausing for #{@pause_for_seconds}s\n"
          sleep @pause_for_seconds
        end
        # nice info for user if skipping 1,000s of tiles
        SLogger.info ".... skipping, skipped #{skipped} total" if ( (skipped) % 100 == 0 )

        # retry with the next proxy if tile has failed
        break unless result.failed == 1
      end

      if all_proxies_failed?
        summary = @proxy_list.map { |proxy| "#{proxy[:url].ljust(50)} => #{proxy[:success].thousands.rjust(5)} succeeded, #{proxy[:failures].thousands.rjust(5)} failed"}.join("\n")
        SLogger.info "\n\n\n Done, no more proxies left\n\n\n#{summary}\n--------------\nProcessed #{tiles.count} tiles: #{successful} successful, #{skipped} skipped, #{failed} failed."
        return
      end
    end
  end

  ##
  # Download the tile from Google and store locally if one does not already exist
  # Returns a result object comprised of successful, skipped or failed with values 0 or 1 (only one param can have 1)
  def download_tile(x,y,zoom)
    result = OpenStruct.new(:successful => 0, :skipped => 0, :failed => 0)

    tile_path = GmapTile.tile_path(x,y,zoom)
    tile_url = GmapTile.replace_tile_vars(AppConfig.gmap_remote_path,x,y,zoom)

    if (File.exists?(tile_path))
      # SLogger.info "Skipping #{tile_name} as file already exists"
      result.skipped = 1
    else
      if execute_wget(tile_url, tile_path)
        SLogger.info "Downloaded #{tile_url} to #{tile_path}\n"
      else
        SLogger.warn "Failed to download #{tile_url} to #{tile_name}. Err: #{$?.inspect}\n"
      end
      if is_image_valid?(tile_path)
        result.successful = 1
      else
        SLogger.warn "Image is not invalid #{tile_url}"
        File.delete(tile_path) if File.exists?(tile_path)
        result.failed = 1
      end
    end
    result
  end

  # TODO: Move Gmap tiles into a model set of classes i.e. replace_tile_vars should be part of a tiles model

private
  def all_proxies_failed?
    !current_proxy
  end

  def current_proxy
    @proxy_list[@proxy_index]
  end

  def execute_wget(tile_url, tile_path)
    proxy_url = current_proxy[:url]
    encoded_tile_url = CGI.escape(tile_url)

    # iterate through proxy methods for each failure
    proxy_method = @proxy_methods[@proxy_index % @proxy_methods.length]
    post_data = proxy_method[:post_data].gsub(/\{URL\}/, encoded_tile_url)

    SLogger.info("GET #{proxy_url} with map from #{tile_url}")
    Kernel::system("wget -q --post-data=\"#{post_data}\" --output-document=\"#{tile_path}\" #{proxy_url}#{proxy_method[:url]}")
  end

  # log that the download has failed for this proxy
  def log_to_proxy_download_failed()
    if current_proxy
      current_proxy[:failures] += 1
      SLogger.info "#{current_proxy[:failures]} errors now on proxy #{current_proxy[:url]}\n"
      if current_proxy[:failures] >= @proxy_failure_max
        @proxy_index += 1
        SLogger.info "\n\nSwitching to new proxy #{current_proxy[:url]}\n\n" if current_proxy
      end
    end
  end

  # log that the download has succeeded for this proxy
  def log_to_proxy_download_success()
    current_proxy[:success] += 1 if current_proxy
  end

  # returns true if image is valid (checks dimensions and file type)
  def is_image_valid?(image_path)
    if File.exists?(image_path) && (File.size(image_path) > 0)
      open(image_path) do |fh|
        image = ImageSize.new(fh.read)
        # if image width is not nil, then this is a valid image
        return true if (!image.width.blank? && (image.width == AppConfig.gmap_tile_size))
      end
    end
  end
end