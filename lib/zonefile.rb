#
# = Ruby Zonefile - Parse and manipulate DNS Zone Files.
#
# == Description
# This class can read, manipulate and create DNS zone files. It supports A, AAAA, MX, NS, SOA, 
# TXT, CNAME, PTR and SRV records. The data can be accessed by the instance method of the same
# name. All except SOA return an array of hashes containing the named data. SOA directly returns the 
# hash since there can only be one SOA information.
#
# The following hash keys are returned per record type:
#
# * SOA
#    - :ttl, :primary, :email, :serial, :refresh, :retry, :expire, :minimumTTL
# * A
#    - :name, :ttl, :class, :host
# * MX
#    - :name, :ttl, :class, :pri, :host
# * NS
#    - :name, :ttl, :class, :host
# * CNAME
#    - :name, :ttl, :class, :host
# * TXT
#    - :name, :ttl, :class, :text
# * A4 (AAAA)
#    - :name, :ttl, :class, :host
# * PTR
#    - :name, :ttl, :class, :host
# * SRV
#    - :name, :ttl, :class, :pri, :weight, :port, :host
# * DS
#    - :name, :ttl, :class, :key_tag, :algorithm, :digest_type, :digest
# * DNSKEY
#    - :name, :ttl, :class, :flag, :protocol, :algorithm, :public_key
# * RRSIG
#    - :name, :ttl, :class, :type_covered, :algorithm, :labels, :original_ttl,
#      :expiration, :inception, :key_tag, :signer, :signature
# * NSEC
#    - :name, :ttl, :class, :next, :types
# * NSEC3
#    - :name, :ttl, :class, :algorithm, :flags, :iterations, :salt, :next, :types
# * NSEC3PARAM
#    - :name, :ttl, :class, :algorithm, :flags, :iterations, :salt
# * NAPTR
#    - :name, :ttl, :class, :order, :preference, :flags, :service, :regexp, :replacement
#
# == Examples
#
# === Read a Zonefile
#
#  zf = Zonefile.from_file('/path/to/zonefile.db')
#  
#  # Display MX-Records
#  zf.mx.each do |mx_record|
#     puts "Mail Exchagne with priority: #{mx_record[:pri]} --> #{mx_record[:host]}"
#  end
#
#  # Show SOA TTL
#  puts "Record Time To Live: #{zf.soa[:ttl]}"
#
#  # Show A-Records
#  zf.a.each do |a_record|
#     puts "#{a_record[:name]} --> #{a_record[:host]}"
#  end
#
#
# ==== Manipulate a Zonefile
#
#  zf = Zonefile.from_file('/path/to/zonefile.db')
#
#  # Change TTL and add an A-Record
#
#  zf.soa[:ttl] = '123123'	# Change the SOA ttl
#  zf.a << { :class => 'IN', :name => 'www', :host => '192.168.100.1', :ttl => 3600 }  # add A-Record
#
#  # Setting PTR records (deleting existing ones)
#
#  zf.ptr = [ { :class => 'IN', :name=>'1.100.168.192.in-addr.arpa', :host => 'my.host.com' },
#             { :class => 'IN', :name=>'2.100.168.192.in-addr.arpa', :host => 'me.host.com' } ]
#
#  # Increase Serial Number
#  zf.new_serial
#
#  # Print new zonefile
#  puts "New Zonefile: \n#{zf.output}"
#
# == Name attribute magic
#
# Since 1.04 the :name attribute is preserved and returned as defined in a previous record if a zonefile entry
# omits it. This should be the expected behavior for most users.
# You can switch this off globally by calling Zonefile.preserve_name(false)
#
# == Authors
# 
# Martin Boese, based on Simon Flack Perl library DNS::ZoneParse 
#
# Andy Newton, patch to support various additional records
#

class Zonefile

 RECORDS = %w{ mx a a4 ns cname txt ptr srv soa ds dnskey rrsig nsec nsec3 nsec3param naptr }
 attr :records
 attr :soa
 attr :data
# global $ORIGIN option
 attr :origin 
 # global $TTL option
 attr :ttl
 
 @@preserve_name = true

 # For compatibility: This can switches off copying of the :name from the 
 # previous record in a zonefile if found omitted. 
 # This was zonefile's behavior in <= 1.03 .  
 def self.preserve_name(do_preserve_name)
   @@preserve_name = do_preserve_name
 end
 
 def method_missing(m, *args)
   mname = m.to_s.sub("=","")
   return super unless RECORDS.include?(mname)
   
   if m.to_s[-1].chr == '=' then
     @records[mname.intern] = args.first
     @records[mname.intern]
   else 
     @records[m]
   end
 end


 # Compact a zonefile content - removes empty lines, comments, 
 # converts tabs into spaces etc...
 def self.simplify(zf)
    # concatenate everything split over multiple lines in parentheses - remove ;-comments in block
    zf = zf.gsub(/\;[^\'\"]*?$/,'').gsub(/(\([^\)]*?\))/) { |m| m.split(/\n/).map { |l| l.gsub(/\;.*$/, '') }.join("\n").gsub(/[\r\n]/, '').gsub( /[\(\)]/, '') }

    zf.split(/\n/).map do |line|
        r = line.gsub(/\t/, ' ')
        r = r.gsub(/\s+/, ' ')
        		# FIXME: this is ugly and not accurate, couldn't find proper regex:
        		#   Don't strip ';' if it's quoted. Happens a lot in TXT records.
        (0..(r.length - 1)).find_all { |i| r[i].chr == ';' }.each do |comment_idx|
           if !r[(comment_idx+1)..-1].index(/['"]/) then
              r = r[0..(comment_idx-1)]
              break
           end
        end
        r
    end.delete_if { |line| line.empty? || line[0].chr == ';'}.join("\n")
 end


 # create a new zonefile object by passing the content of the zonefile
 def initialize(zonefile = '', file_name= nil, origin= nil)
   @data = zonefile
   @filename = file_name
   @origin = origin || (file_name ? file_name.split('/').last : '')
   @lastname = @origin
   @records = {}
   @soa = {}
   RECORDS.each { |r| @records[r.intern] = [] }
   parse
 end
 
 # True if no records (except sao) is defined in this file
 def empty?
   RECORDS.each do |r|
      return false unless @records[r.intern].empty?
   end
   true
 end
 
 # Create a new object by reading the content of a file
 def self.from_file(file_name, origin = nil)
    Zonefile.new(File.read(file_name), file_name.split('/').last, origin)
 end
 
 def add_record(type, data= {})
    if @@preserve_name then
      @lastname = data[:name] if data[:name].to_s != ''
      data[:name] = @lastname if data[:name].to_s == ''
    end
    @records[type.downcase.intern] << data
 end
 
 # Generates a new serial number in the format of YYYYMMDDII if possible
 def new_serial
   base = "%04d%02d%02d" % [Time.now.year, Time.now.month, Time.now.day ]

   if ((@soa[:serial].to_i / 100) > base.to_i) then
       ns = @soa[:serial].to_i + 1
       @soa[:serial] = ns.to_s
       return ns.to_s
   end
   
   ii = 0
   while (("#{base}%02d" % ii).to_i <= @soa[:serial].to_i) do
    ii += 1
   end
   @soa[:serial] = "#{base}%02d" % ii   
 end

 def parse_line(line)
    valid_name = /[\@a-z_\-\.0-9\*]+/i
    valid_ip6  = /[\@a-z_\-\.0-9\*:]+/i
    rr_class   = /\b(?:IN|HS|CH)\b/i
    rr_type    = /\b(?:NS|A|CNAME)\b/i
    rr_ttl     = /(?:\d+[wdhms]?)+/i
    ttl_cls    = Regexp.new("(?:(#{rr_ttl})\s)?(?:(#{rr_class})\s)?")
    base64     = /([\s\w\+\/]*=*)/i
    hexadeimal = /([\sA-F0-9]*)/i
    quoted     = /(\"[^\"]*\")/i

    data = {}
    if line =~ /^\$ORIGIN\s*(#{valid_name})/ix then
        @origin = @lastname = $1
    elsif line =~ /^(#{valid_name})? \s*
                 #{ttl_cls}
                 (#{rr_type}) \s
                 (#{valid_name})
               /ix then
              (name, ttl, dclass, type, host) = [$1, $2, $3, $4, $5]
             add_record($4, :name => $1, :ttl => $2, :class => $3, :host => $5)
    elsif line=~/^(#{valid_name})? \s*
                #{ttl_cls}
                AAAA \s
                (#{valid_ip6})               
                /x then
              add_record('a4', :name => $1, :ttl => $2, :class => $3, :host => $4)
    elsif line=~/^(#{valid_name})? \s*
                 #{ttl_cls}
                 MX \s
                 (\d+) \s
                 (#{valid_name})
               /ix then
               add_record('mx', :name => $1, :ttl => $2, :class => $3, :pri => $4.to_i, :host => $5)
    elsif line=~/^(#{valid_name})? \s*
                 #{ttl_cls}
                 SRV \s
                 (\d+) \s
                 (\d+) \s
                 (\d+) \s
                 (#{valid_name})
               /ix
	       add_record('srv', :name => $1, :ttl => $2, :class => $3, :pri => $4, :weight => $5,
	                         :port => $6, :host => $7)
    elsif line=~/^(#{valid_name})? \s*
                #{ttl_cls}
                DS \s
                (\d+) \s
                (\w+) \s
                (\d+) \s
                #{hexadeimal}
                /ix
        add_record( 'ds', :name => $1, :ttl => $2, :class => $3, :key_tag => $4.to_i, :algorithm => $5,
                    :digest_type => $6.to_i, :digest => $7.gsub( /\s/,'') )
    elsif line=~/^(#{valid_name})? \s*
                #{ttl_cls}
                NSEC \s
                (#{valid_name}) \s
                ([\s\w]*)
                /ix
      add_record( 'nsec', :name => $1, :ttl => $2, :class => $3, :next => $4, :types => $5.strip )
    elsif line=~/^(#{valid_name})? \s*
                #{ttl_cls}
                NSEC3 \s
                (\d+) \s
                (\d+) \s
                (\d+) \s
                (-|[A-F0-9]*) \s
                ([A-Z2-7=]*) \s
                ([\s\w]*)
                /ix
      add_record( 'nsec3', :name => $1, :ttl => $2, :class => $3, :algorithm => $4, :flags => $5,
                   :iterations => $6, :salt => $7, :next => $8.strip, :types => $9.strip )
    elsif line=~/^(#{valid_name})? \s*
                #{ttl_cls}
                NSEC3PARAM \s
                (\d+) \s
                (\d+) \s
                (\d+) \s
                (-|[A-F0-9]*)
                /ix
      add_record( 'nsec3param', :name => $1, :ttl => $2, :class => $3, :algorithm => $4, :flags => $5,
                  :iterations => $6, :salt => $7 )
    elsif line=~/^(#{valid_name})? \s*
                #{ttl_cls}
                DNSKEY \s
                (\d+) \s
                (\d+) \s
                (\w+) \s
                #{base64}
                /ix
      add_record( 'dnskey', :name => $1, :ttl => $2, :class => $3, :flag => $4.to_i, :protocol => $5.to_i,
                  :algorithm => $6, :public_key => $7.gsub( /\s/,'') )
    elsif line=~/^(#{valid_name})? \s*
                #{ttl_cls}
                RRSIG \s
                (\w+) \s
                (\w+) \s
                (\d+) \s
                (\d+) \s
                (\d+) \s
                (\d+) \s
                (\d+) \s
                (#{valid_name}) \s
                #{base64}
                /ix
      add_record( 'rrsig', :name => $1, :ttl => $2, :class => $3, :type_covered => $4, :algorithm => $5,
                  :labels => $6.to_i, :original_ttl => $7.to_i, :expiration => $8.to_i, :inception => $9.to_i,
                  :key_tag => $10.to_i, :signer => $11, :signature => $12.gsub( /\s/,'')  )
    elsif line=~/^(#{valid_name})? \s*
                #{ttl_cls}
                NAPTR \s
                (\d+) \s
                (\d+) \s
                #{quoted} \s
                #{quoted} \s
                #{quoted} \s
                (#{valid_name})
                /ix
      add_record( 'naptr', :name => $1, :ttl => $2, :class => $3, :order => $4.to_i, :preference => $5.to_i,
                  :flags => $6, :service => $7, :regexp => $8, :replacement => $9 )
    elsif line=~/^(#{valid_name}) \s+
                 #{ttl_cls}
                 SOA \s+
                 (#{valid_name}) \s+
                 (#{valid_name}) \s*
                 \s*
                     (#{rr_ttl}) \s+
                     (#{rr_ttl}) \s+
                     (#{rr_ttl}) \s+
                     (#{rr_ttl}) \s+
                     (#{rr_ttl}) \s*
               /ix
            ttl = @soa[:ttl] || $2 || ''
            @soa[:origin] = $1
            @soa[:ttl] = ttl
            @soa[:primary] = $4
            @soa[:email] = $5
            @soa[:serial] = $6
            @soa[:refresh] = $7
            @soa[:retry] = $8
            @soa[:expire] = $9
            @soa[:minimumTTL] = $10
            @lastname = $1
    elsif line=~ /^(#{valid_name})? \s*
                #{ttl_cls}
                PTR \s+
                (#{valid_name})
               /ix
            add_record('ptr', :name => $1, :class => $3, :ttl => $2, :host => $4)
    elsif line =~ /^(#{valid_name})? \s* #{ttl_cls} TXT \s+ (.*)$/ix
             add_record('txt', :name => $1, :ttl => $2, :class => $3, :text => $4.strip)
    elsif line =~ /\$TTL\s+(#{rr_ttl})/i 
            @ttl = $1
    end
 end

 def parse
    Zonefile.simplify(@data).each_line do |line|
        parse_line(line)      
    end
 end
 
 
 # Build a new nicely formatted Zonefile
 #
 def output
    out =<<-ENDH
;
;  Database file #{@filename || 'unknown'} for #{@origin || 'unknown'} zone.
;	Zone version: #{self.soa[:serial]}
;
#{self.soa[:origin]}		#{self.soa[:ttl]} IN  SOA  #{self.soa[:primary]} #{self.soa[:email]} (
				#{self.soa[:serial]}	; serial number
				#{self.soa[:refresh]}	; refresh
				#{self.soa[:retry]}	; retry
				#{self.soa[:expire]}	; expire
				#{self.soa[:minimumTTL]}	; minimum TTL
				)

#{@origin ? "$ORIGIN #{@origin}" : ''}
#{@ttl ? "$TTL #{@ttl}" : ''}
				
; Zone NS Records
ENDH
   self.ns.each do |ns|
     out <<  "#{ns[:name]}	#{ns[:ttl]}	#{ns[:class]}	NS	#{ns[:host]}\n"
   end
   out << "\n; Zone MX Records\n" unless self.mx.empty?
   self.mx.each do |mx|
     out << "#{mx[:name]}	#{mx[:ttl]}	#{mx[:class]}	MX	#{mx[:pri]} #{mx[:host]}\n"
   end
   
   out << "\n; Zone A Records\n" unless self.a.empty?
   self.a.each do |a|
        out <<  "#{a[:name]}	#{a[:ttl]}	#{a[:class]}	A	#{a[:host]}\n"
   end   

   out << "\n; Zone CNAME Records\n" unless self.cname.empty?
   self.cname.each do |cn|
     out << "#{cn[:name]}	#{cn[:ttl]}	#{cn[:class]}	CNAME	#{cn[:host]}\n"
   end  

   out << "\n; Zone AAAA Records\n" unless self.a4.empty?
   self.a4.each do |a4|
     out << "#{a4[:name]}	#{a4[:ttl]}	#{a4[:class]}	AAAA	#{a4[:host]}\n"
   end

   out << "\n; Zone TXT Records\n" unless self.txt.empty?
   self.txt.each do |tx|
     out << "#{tx[:name]}	#{tx[:ttl]}	#{tx[:class]}	TXT	#{tx[:text]}\n"
   end

   out << "\n; Zone SRV Records\n" unless self.srv.empty?
   self.srv.each do |srv|
     out << "#{srv[:name]}	#{srv[:ttl]}	#{srv[:class]}	SRV	#{srv[:pri]} #{srv[:weight]} #{srv[:port]}	#{srv[:host]}\n"
   end
   
   out << "\n; Zone PTR Records\n" unless self.ptr.empty?
   self.ptr.each do |ptr|
     out << "#{ptr[:name]}	#{ptr[:ttl]}	#{ptr[:class]}	PTR	#{ptr[:host]}\n"
   end

   out << "\n; Zone DS Records\n" unless self.ds.empty?
   self.ds.each do |ds|
     out << "#{ds[:name]} #{ds[:ttl]} #{ds[:class]} DS #{ds[:key_tag]} #{ds[:algorithm]} #{ds[:digest_type]} #{ds[:digest]}\n"
   end

   out << "\n; Zone NSEC Records\n" unless self.ds.empty?
   self.nsec.each do |nsec|
     out << "#{nsec[:name]} #{nsec[:ttl]} #{nsec[:class]} NSEC #{nsec[:next]} #{nsec[:types]}\n"
   end

   out << "\n; Zone NSEC3 Records\n" unless self.ds.empty?
   self.nsec3.each do |nsec3|
     out << "#{nsec3[:name]} #{nsec3[:ttl]} #{nsec3[:class]} NSEC3 #{nsec3[:algorithm]} #{nsec3[:flags]} #{nsec3[:iterations]} #{nsec3[:salt]} #{nsec3[:next]} #{nsec3[:types]}\n"
   end

   out << "\n; Zone NSEC3PARAM Records\n" unless self.ds.empty?
   self.nsec3param.each do |nsec3param|
     out << "#{nsec3param[:name]} #{nsec3param[:ttl]} #{nsec3param[:class]} NSEC3PARAM #{nsec3param[:algorithm]} #{nsec3param[:flags]} #{nsec3param[:iterations]} #{nsec3param[:salt]}\n"
   end

   out << "\n; Zone DNSKEY Records\n" unless self.ds.empty?
   self.dnskey.each do |dnskey|
     out << "#{dnskey[:name]} #{dnskey[:ttl]} #{dnskey[:class]} DNSKEY #{dnskey[:flag]} #{dnskey[:protocol]} #{dnskey[:algorithm]} #{dnskey[:public_key]}\n"
   end

   out << "\n; Zone RRSIG Records\n" unless self.ds.empty?
   self.rrsig.each do |rrsig|
     out << "#{rrsig[:name]} #{rrsig[:ttl]} #{rrsig[:class]} RRSIG #{rrsig[:type_covered]} #{rrsig[:algorithm]} #{rrsig[:labels]} #{rrsig[:original_ttl]} #{rrsig[:expiration]} #{rrsig[:inception]} #{rrsig[:key_tag]} #{rrsig[:signer]} #{rrsig[:signature]}\n"
   end

   out << "\n; Zone NAPTR Records\n" unless self.ds.empty?
   self.naptr.each do |naptr|
     out << "#{naptr[:name]} #{naptr[:ttl]} #{naptr[:class]} NAPTR #{naptr[:order]} #{naptr[:preference]} #{naptr[:flags]} #{naptr[:service]} #{naptr[:regexp]} #{naptr[:replacement]}\n"
   end

   out
 end

end

