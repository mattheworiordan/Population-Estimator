# Exmouth, UK, 50.6197493, -3.4134097

class MercatorProjection
  # Ported to Ruby from http://code.google.com/p/gheat/source/browse/trunk/__/lib/python/gmerc.py
  #
  # This is a port of Google's GMercatorProjection.fromLatLngToPixel.
  # Doco on the original:
  # http://code.google.com/apis/maps/documentation/reference.html#GMercatorProjection
  # Here's how I ported it:
  # http://blag.whit537.org/2007/07/how-to-hack-on-google-maps.html

  # The goofy variable names below are an artifact of Google's javascript obfuscation.

  CBK = [128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216, 33554432, 67108864, 134217728, 268435456, 536870912, 1073741824, 2147483648, 4294967296, 8589934592, 17179869184, 34359738368, 68719476736, 137438953472]
  CEK = [0.7111111111111111, 1.4222222222222223, 2.8444444444444446, 5.688888888888889, 11.377777777777778, 22.755555555555556, 45.51111111111111, 91.02222222222223, 182.04444444444445, 364.0888888888889, 728.1777777777778, 1456.3555555555556, 2912.711111111111, 5825.422222222222, 11650.844444444445, 23301.68888888889, 46603.37777777778, 93206.75555555556, 186413.51111111112, 372827.02222222224, 745654.0444444445, 1491308.088888889, 2982616.177777778, 5965232.355555556, 11930464.711111112, 23860929.422222223, 47721858.844444446, 95443717.68888889, 190887435.37777779, 381774870.75555557, 763549741.5111111]
  CFK = [40.74366543152521, 81.48733086305042, 162.97466172610083, 325.94932345220167, 651.8986469044033, 1303.7972938088067, 2607.5945876176133, 5215.189175235227, 10430.378350470453, 20860.756700940907, 41721.51340188181, 83443.02680376363, 166886.05360752725, 333772.1072150545, 667544.214430109, 1335088.428860218, 2670176.857720436, 5340353.715440872, 10680707.430881744, 21361414.86176349, 42722829.72352698, 85445659.44705395, 170891318.8941079, 341782637.7882158, 683565275.5764316, 1367130551.1528633, 2734261102.3057265, 5468522204.611453, 10937044409.222906, 21874088818.445812, 43748177636.891624]

  class << self
    def lat_long_to_px(latitude, longitude, zoom)
      # Given two floats and an int, return a 2-tuple of ints.
      # Note that the pixel coordinates are tied to the entire map, not to the map
      # section currently in view.

      raise "Zoom must be an int from 0 to 30" unless (0..30).include?(zoom)
      latitude = latitude.to_f unless latitude.kind_of?(Float)
      longitude = longitude.to_f unless longitude.kind_of?(Float)

      cbk = CBK[zoom].to_f

      x = (cbk + (longitude * CEK[zoom])).round

      foo = Math.sin(latitude * Math::PI / 180)
      if foo < -0.9999
        foo = -0.9999
      elsif foo > 0.9999
        foo = 0.9999
      end

      y = (cbk + (0.5 * Math.log((1+foo)/(1-foo)) * (-CFK[zoom]))).round

      [x, y]
    end

    def px_to_lat_long(x, y, zoom)
      # Given three ints, return a 2-tuple of floats.
      # Note that the pixel coordinates are tied to the entire map, not to the map
      # section currently in view.

      raise "Latitude must be a float" unless x.kind_of?(Integer)
      raise "Longitude must be a float" unless y.kind_of?(Integer)
      raise "Zoom must be an int from 0 to 30" unless (0..30).include?(zoom)

      foo = CBK[zoom]
      longitude = (x - foo) / CEK[zoom]
      bar = (y - foo) / -CFK[zoom]
      blam = 2 * Math.atan(Math.exp(bar)) - Math::PI / 2
      latitude = blam / (Math::PI / 180)

      [latitude, longitude]
    end
  end
end