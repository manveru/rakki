class Dot
  include Innate::Node
  map '/dot'

  def generate
    png = `bin/graph`
    FileUtils.cp(png 'public/graph.png')
  end
end
