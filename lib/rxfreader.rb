#!/usr/bin/env ruby

# file: rxfreader.rb


require 'gpd-request'
require 'rest-client'
require 'drb_fileclient-reader'


# RXF originally stands for Read XML File.


module RXFRead

  class FileX

    def self.exists?(filename)

      type = FileX.filetype(filename)

      filex = case type
      when :file
        File
      when :dfs
        DfsFile
      else
        nil
      end

      return nil unless filex

      filex.exists? filename

    end


    def self.filetype(x)

      return :string if x.lines.length > 1

      case x
      when /^https?:\/\//
        :http
      when /^dfs:\/\//
        :dfs
      when /^file:\/\//
        :file
      else

        if File.exists?(x) then
          :file
        else
          :text
        end

      end
    end

    def self.read(x)
      RXFReader.read(x).first
    end

  end
end


class RXFReaderException < Exception
end

class RXFReader
  using ColouredText

  def self.read(x, h={})

    opt = {debug: false, auto: false}.merge(h)

    debug = opt[:debug]

    raise RXFReaderException, 'nil found, expected a string' if x.nil?

    if x.strip[/^<(\?xml|[^\?])/] then

      [x, :xml]

    elsif x.lines.length == 1 then

      if x[/^https?:\/\//] then

        puts 'before GPDRequest'.info if debug

        r = if opt[:username] and opt[:password] then
          GPDRequest.new(opt[:username], opt[:password]).get(x)
        else
          response = RestClient.get(x)
        end

        case r.code
        when '404'
          raise(RXFReaderException, "404 %s not found" % x)
        when '401'
          raise(RXFReaderException, "401 %s unauthorized access" % x)
        end

        [r.body, :url]

      elsif  x[/^dfs:\/\//] then

        r = DfsFile.read(x).force_encoding('UTF-8')
        [r, :dfs]


      elsif x[/^file:\/\//] or File.exists?(x) then

        puts 'RXFHelper.read before File.read' if debug
        contents = File.read(File.expand_path(x.sub(%r{^file://}, '')))

        [contents, :file]

      elsif x =~ /\s/
        [x, :text]
      elsif DfsFile.exists?(x)
        [DfsFile.read(x).force_encoding('UTF-8'), :dfs]
      else
        [x, :unknown]
      end

    else

      [x, :unknown]
    end
  end

end
