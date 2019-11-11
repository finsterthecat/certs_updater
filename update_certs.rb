require 'csv'
require 'set'
#
# inputs
# certs.csv file
# consultants.csv file
# sf.csv file

# Fix encoding errors. Also fix newlines to make them consistent.
def fix_encoding_errors(s)
    if ! s.valid_encoding?
        s.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
    else
        s
    end \
        .tr("\r","")
end
#reformat date from mm/dd/yyyy to yyyymmdd
def date_reformat(mmddyyyy)
    dt_arr = mmddyyyy.split("/").map{|x| "%02d" % x.to_i}
    "#{dt_arr[2]}#{dt_arr[0]}#{dt_arr[1]}"
end

#Update a cert in the hash if date is equal or later or insert if not found
#:contingent: found in certs but not in sf;
#:new: found in sf but not in certs;
#:confirmed: same cert and date found in sf and certs,
#:updated: same cert and later date found in sf
#params: Hash: the hash to update, consultant, consultant_source = enum(:certs, :sf)
def update_cert(hash, consultant, consultant_source = :certs)
    name = consultant[0].downcase
    instance = hash.fetch(name, {})  #List of certs for consultant, empty list if consultant not found
    cert = instance.fetch(consultant[1], nil)          #Get cert by cert name, nil if not found
    dt = date_reformat(consultant[2])
    if (cert == nil || consultant_source == :sf || dt >= cert[0]) then #Store this cert if current or new cert
        src = 
            if consultant_source == :sf
                if cert == nil
                    :new
                elsif cert[2] == :contingent
                    if dt < cert[0]
                        :older
                    elsif dt == cert[0]
                        :confirmed
                    else
                        :updated
                    end
                else
                    if dt < cert[0]
                        :skip
                    elsif dt == cert[0]
                        cert[2]
                    else
                        :updated
                    end
                end
            else
                :contingent
            end
        if src != :skip
            instance.store(consultant[1], [dt, consultant[3], src, src == :older ? cert[0] : ""])
        end
    end
    hash.store(name , instance)       #Put cert list back for consultant
    hash
end

#certs: [name, cert, date, advancedFlag]
c = fix_encoding_errors(File.read('certs.csv'))
certs = CSV.parse(c)
#certhash: k is consultant name,
#           v is hash:
#               k: cert,
#               v: [date, advancedFlag, disposition(existing, new, confirmed, or updated)]
certhash = certs.inject({}) {|s,cert| update_cert(s, cert, :certs) }

originalCerts = Hash[ certhash ] #Remember original list for later

#masternames: list of consultant names.
master = fix_encoding_errors(File.read('consultants.csv'))
masterNames =
        CSV.parse(master).map do |x|
            n = x[0].split(',');
            n.size == 2 ?
                (n[1] + " " + n[0]).strip.downcase :
                "?"
        end

#sflist: list of consultant certs from sf: [name, cert, date, advancedFlag]
sf = fix_encoding_errors(File.read('sf.csv'))
sfList = CSV.parse(sf)
sfList.each{|x| x[2] = "01/01/1900" if x[2] == "-"} #Fix missing dates

#update the certhash with the salesforce records
sfCount = 0
sfList.each do |sf|
    update_cert(certhash, sf, :sf)
    sfCount += 1
end

puts "#{sfCount} Salesforce matches"

sortCerts = Hash[ certhash.sort_by{|name, value| name }]

CSV.open('updated_certs.csv', 'w') do |csv|
    csv << ["Name", "Certificate", "Date", "Advanced", "In Master", "Debut", "New Cert"]
    sortCerts.each do |name, value|
        value.each do |c, v|
            dt = "#{v[0][4,2]}/#{v[0][6,2]}/#{v[0][0,4]}"
            csv << [name.split().map{|x| x.capitalize}.join(" "),
                    c,
                    dt,
                    v[1],
                    masterNames.include?(name) ? 1 : 0,
                    originalCerts.include?(name) ? 0 : 1,
                    v[2],
                    v[3] != "" ? "#{v[3][4,2]}/#{v[3][6,2]}/#{v[3][0,4]}" : ""]
        end
    end
end 
