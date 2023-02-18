#!/usr/bin/env ruby

# file: rxfreader.rb

require 'net/http'
require 'uri'
require 'gpd-request'
require 'rest-client'
require 'drb_fileclient-reader'


# RXF originally stands for Read XML File.


module RXFRead

  class FileX

    def self.dirname(s)   RXFReader.dirname(s)      end    
    def self.exist?(s)    RXFReader.exist?(s)       end    
    def self.exists?(s)   RXFReader.exist?(s)       end
    def self.filetype(s)  RXFReader.filetype(s)     end
    def self.read(s)      RXFReader.read(s).first   end

  end

end


class RXFReaderException < Exception
end

class RXFReader
  using ColouredText

  def self.dirname(s)
    File.dirname s
  end
  
  def self.exist?(filename)

    type = self.filetype(filename)

    filex = case type
    when :file
      File
    when :dfs
      DfsFile
    else
      nil
    end

    return nil unless filex

    filex.exist? filename

  end
  
  def self.exists?(filename)
    self.exist?(filename)
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

      if File.exist?(x) then
        :file
      else
        :text
      end

    end
  end

  def self.read(x, h={})   
    
    opt = {debug: false, auto: false}.merge(h)
    
    debug = opt[:debug]

    raise RXFReaderException, 'nil found, expected a string' if x.nil?

    if x.class.to_s =~ /Rexle$/ then

      [x.xml, :rexle]

    elsif x.strip[/^<(\?xml|[^\?])/] then
      
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
        

      elsif x[/^file:\/\//] or File.exist?(x) then
        
        puts 'RXFHelper.read before File.read' if debug
        contents = File.read(File.expand_path(x.sub(%r{^file://}, '')))
        
        [contents, :file]
        
      elsif x =~ /\s/
        [x, :text]
      elsif DfsFile.exist?(x)
        [DfsFile.read(x).force_encoding('UTF-8'), :dfs]
      else
        [x, :unknown]
      end
      
    else

      [x, :unknown]
    end
  end

  def self.reveal(uri_str, a=[])

    u = URI.parse(uri_str)
    response = Net::HTTP.get_response(u)

    url = case response
      when Net::HTTPRedirection then response['location']
    end

    return a << uri_str if url.nil?
    url.prepend u.origin if not url[/^http/]

    reveal(url, a << uri_str)
  end

  
end
