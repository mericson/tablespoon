require 'google_drive'
require 'pp'

module Tablespoon

  class Doc
    
    attr_reader :session, :doc
    
    def initialize( key, opts = {} )
      if opts[:username] && opts [:password]
        @session = GoogleDrive.login( opts[:username], opts[:password] )
        @doc   = session.spreadsheet_by_key( key )
      else
        raise "No username and password" 
      end
    end

    def get_table( x, opts = {} )

      if x.class == String
        return Table.new @doc.worksheet_by_title( x ), opts
      else
        return Table.new @doc.worksheets[x], opts
      end
      
    end

  end
  
  class Table

    include Enumerable
    
    attr_accessor :doc, :ws, :column_map, :field_map, :id_field, :include_blank_rows
    
    def initialize( ws, opts = {} ) 
      @ws = ws

      # handle some options
      @id_field = opts[:id_field]
      @include_blank_row = opts[:include_blank_rows] || true

      build_column_map

      # build data array
      
      @rows = []
      
      for row in 2..@ws.num_rows
        r = Record.new self
        r.row_num = row 
        
        data = {}
        
        for col in 1..@ws.num_cols
          data[ column_map[col] ] = @ws[ row, col ]
          
          if column_map[col] == @id_field
            r.id = @ws[ row, col ]
          end
        end
        
        r.data=data
        
        @rows << r

      end
      
    end

    def []
      return @rows[i]
    end

    def add_row
      r = Record.new self
      r.row_num = @ws.num_rows + 1
      r.data = {}

      r
    end

    def length
      return @rows.length
    end
    
    def last
      return @rows.last
    end

    def each
      @rows.each { |i| yield i }
    end

    def find( field, value )
      @rows.find { |r| r[field] == value }
    end
    
    def find_by_id( value )
      @rows.find { |r| r.id == value }
    end

    def find_all( field, value )
      @rows.select { |r| r[field] == value }
    end

    def save
      @ws.save
    end
    
    def build_column_map
      @column_map    = {}
      for col in 1..@ws.num_cols      
        @column_map[ col ] = @ws[ 1,col ]
      end
      
      @field_map = column_map.invert
    end

    def dump
      output = []

      @rows.each do |r|
        output << r.data
      end

      output 
    end

    
    
  end

  class Record

    attr_accessor :row_num, :id, :data

    def [] (field)
      return @data[field]
    end

    def []= (field,value)

      ## get the column number where we think it is
      ## if it's not there, rebuild the field map
      ## and try again
      
      col_num = get_col_num( field )
      row_num = @row_num
      
      @ws[row_num, col_num] = value

      @ws.save
      
      if field == @id_field
        @id = value
      end
      
    end
    
    def get_col_num( field )

      col_num = @field_map[field]

      if ! @ws[1,col_num] == field
        @table.build_column_map
        col_num = @field_map[field]
        
        if ! @ws[1,col_num] == field
          raise "Unable to find field #{field}"
        end
      end
      
      return col_num

    end

    def initialize( table )
      
      @table      = table
      
      @field_map  = table.field_map
      @ws         = table.ws
      @id_field   = table.id_field
      
      @data  = {}
      
    end

    def to_s
      return "Row #{@row_num} Id #{@id} " + @data.keys.collect { |a| "#{a}: #{@data[a]}" }.join(' - ')
    end
    
  end

end
