module NumberFormatter
  def thousands
    self.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
  end
end

class Fixnum; include NumberFormatter; end
class String; include NumberFormatter; end

