require 'image_size'

class ImportGmapTiles
	
	## TODO: Add in randomisation of Proxy (possibly)
	## TODO: Collect list of failed tiles to be processed again at the end with a working proxy
	
	def initialize()
		@zoom_range = (AppConfig.gmap_min_zoom..AppConfig.gmap_max_zoom).to_a
		@pause_after = 10
		@pause_for_seconds = 2
		
		# used proxy list from here http://www.publicproxyservers.com/proxy/list_rating1.html
		#		test with this URL http://mt2.google.com/vt/x=125&y=86&z=8
		@proxy_index = 0
		@proxies = [ 
			{ :url => nil, :failures => 0}, # Comment this one out if you don't want to hit Google directly and get banned pretty quickly
			{ :url => "http://www.proxg.info/browse.php?b=28&f=norefer&u=$url_no_protocol", :failures => 0},
			{ :url => "http://www.fggg.info/browse.php?b=4&f=norefer&u=$url", :failures => 0},
			{ :url => "http://www.iloveprivacy.eu/browse.php?b=4&f=norefer&u=$url", :failures => 0},
			{ :url => "http://www.getpastit.info/browse.php?b=28&f=norefer&u=$url_no_protocol", :failures => 0},
			{ :url => "http://www.myfetch4you.info/browse.php?b=0&f=norefer&u=$url", :failures => 0},
			{ :url => "http://faceb00k.in/browse.php?b=0&f=norefer&u=$url", :failures => 0},
			{ :url => "http://www.firsthide.info/browse.php?b=0&f=norefer&u=$url", :failures => 0},
			{ :url => "http://www.myfetch4you.info/browse.php?b=0&f=norefer&u=$url", :failures => 0},
			{ :url => "http://www.nameview.info/surf.php?b=0&f=norefer&u=$url", :failures => 0},
			{ :url => "http://www.mywayin.info/browse.php?b=0&f=norefer&u=$url", :failures => 0},
			{ :url => "http://www.enjoyaccess.info/browse.php?b=0&f=norefer&u=$url", :failures => 0}
		]
		@proxy_failure_max = 5
	end
	
	##
	# Start importing all Google Map tiles which we don't have locally in the db path
	# 
	def start(*options)
		tiles = []
		@zoom_range.each do |zoom| 
			# build up array of arrays for all tile combos in structure [x,y,zoom]
			#	 i.e. for zoom 1 we have a range of 0-1 in x & y dimension
			#	 so array is built up as 0,0,1, 0,1,1, 1,0,1, 1,1,1
			tiles.concat( ( (0...2**zoom).to_a*(2**zoom) ).zip( ( (0...2**zoom).to_a*(2**zoom) ).sort, [zoom] * 4**zoom) )
		end
		
		SLogger.info "Zoom range including #{@zoom_range.to_a.join(',')} requires #{tiles.length} tiles"
		
		successfully_processed = 0
		total_processed = 0
		tiles.each do |tile|
			x,y,zoom = tile
			total_processed = total_processed.next
			
			successfully_processed = successfully_processed.next if download_tile(x,y,zoom)
			
			if ( (successfully_processed+1) % @pause_after == 0 )
				SLogger.info "\n---- Downloaded #{total_processed}/#{tiles.count} tiles (#{successfully_processed} successful, #{total_processed-successfully_processed} skipped/failed), pausing for #{@pause_for_seconds}s to maintain sensible throttle\n" 
				sleep @pause_for_seconds
			end
		end
	end

	##
	# Download the tile from Google and store locally if one does not already exist
	# Returns true if a valid tile is downloaded
	def download_tile(x,y,zoom)
		tile_name = replace_vars(AppConfig.gmap_file_path,x,y,zoom)
		tile_url = replace_vars(AppConfig.gmap_remote_path,x,y,zoom)
		tile_path = Rails.root.join('db',AppConfig.gmap_db_path,tile_name)
		
		if (File.exists?(tile_path))
			SLogger.info "Skipping #{tile_name} as file already exists"
			false
		else
			if execute_wget(tile_url, tile_path)
				SLogger.info "Downloaded #{tile_url} to #{tile_path}\n"
			else
				SLogger.warn "Failed to download #{tile_url} to #{tile_name}. Err: #{$?.inspect}\n"
			end
			is_image_valid_and_if_not_delete?(tile_path)
		end
	end
	
private
	def replace_vars(str,x,y,zoom)
		str.gsub(/\$x/, x.to_s).gsub(/\$y/, y.to_s).gsub(/\$z/, zoom.to_s)
	end
	
	def execute_wget(tile_url, tile_path)
		url_with_proxy = get_url_with_proxy(tile_url)
		cookie_path = Rails.root.join('db',AppConfig.gmap_db_path,"proxy_cookie.txt")
		ignore_path = Rails.root.join('db',AppConfig.gmap_db_path,"temp.html")
		proxy = @proxies[@proxy_index]
		
		# do a simple request to get the cookies if using a proxy
		cookies = ""
		if (proxy[:url])
			File.delete(ignore_path) if File.exists?(ignore_path)
			cookies = "--cookies=on --keep-session-cookies --save-cookies=\"#{cookie_path}\""
			Kernel::system("wget -q #{cookies} --output-document=\"#{ignore_path}\" \"#{proxy[:url]}\"")
			cookies = cookies.gsub(/--save-cookies/, "--load-cookies")
		end
		SLogger.info("GET #{url_with_proxy}")
		Kernel::system("wget -nv #{cookies} --output-document=\"#{tile_path}\" \"#{url_with_proxy}\"")
	end
	
	def get_url_with_proxy(url)
		raise "Run out of proxies to use, can no longer download tiles unfortunately. \n\nStopping as no point continuing...." if @proxy_index >= @proxies.count
		
		# if there is a URL to use as a proxy then encode the URL and replace the $url parameter
		if @proxies[@proxy_index][:url]
			@proxies[@proxy_index][:url].sub( /\$url_no_protocol/i, CGI.escape(url.sub(/^\w+/i, "")) )
			@proxies[@proxy_index][:url].sub( /\$url/i, CGI.escape(url) )
		else
			url
		end
	end
	
	def download_failed()
		proxy = @proxies[@proxy_index]
		if proxy
			proxy[:failures] = proxy[:failures].next
			SLogger.info "#{proxy[:failures]} errors now on proxy #{proxy[:url]}\n"
			if proxy[:failures] >= @proxy_failure_max
				@proxy_index = @proxy_index.next
				SLogger.info "\n\nSwitching from proxy #{proxy[:url]} to #{@proxies[@proxy_index][:url]}\n\n" if @proxies[@proxy_index]
			end
		end
	end
	
	def is_image_valid_and_if_not_delete?(image_path)
		if File.exists?(image_path) && (File.size(image_path) > 0)
			open(image_path) do |fh| 
				image = ImageSize.new(fh.read)
				# if image width is not nil, then this is a valid image
				return true if (!image.width.blank? && (image.width == AppConfig.gmap_tile_size))
			end
		end
		File.delete(image_path)
		download_failed
	end
end