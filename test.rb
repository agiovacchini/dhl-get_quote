#require 'dhl-get_quote'
require 'date'
require "word_wrap/core_ext"
require 'nokogiri'
require 'builder'
require 'I18n'
#require 'active_shipping'
require 'prawn'

#            dhlAccount = 106439867
#          else
#             dhlAccount = 106798643
r = Dhl::GetQuote::Request.new(
  :site_id => "rubensga",
  :password => "3VaMNRCn5z",
  :test_mode => false
)

r.metric_measurements!

r.payment_account_number(106798643)

r.from('IT', '47121')
r.to('GB', 'W6 0RX')

r.pieces << Dhl::GetQuote::Piece.new(
  :weight => 10.0
)

r.add_special_service("WY")
puts r.to_xml
response = r.post

puts "response: #{response}"
#response.offered_services.each do |mkts|
#   puts mkts.name
#   puts mkts.code
#end
#puts

File.open('dhl.xml', 'w') { |file| file.write(response.raw_xml) }

if response.error?
   raise "There was an error: #{response.raw_xml}"
else
   puts "Your cost to ship will be: #{response.total_amount} in #{response.currency_code}."
end


return

fedex = ActiveShipping::FedEx.new(test: true, login: '114032805', password: 'CZ9NH0jb1zcPLFAJoURH3z0HA', key: 'I0EnX7TGPavuidyJ', account: '802770847')
#tracking_info = fedex.find_tracking_info('568838414941', carrier_code: 'fedex_ground') # Ground package
#
#tracking_info.shipment_events.each do |event|
#   puts "#{event.name} at #{event.location.city}, #{event.location.state} on #{event.time}. #{event.message}"
#end

# Package up a poster and a Wii for your nephew.


# You live in Beverly Hills, he lives in Ottawa
origin = ActiveShipping::Location.new(country: 'US',
                                      state: 'CA',
                                      city: 'Beverly Hills',
                                      zip: '90210',
                                      name: 'topa',
                                      company: 'gigia',
                                      phone: '23232332',
                                      address1: 'via dei mille')

destination = ActiveShipping::Location.new(country: 'US',
                                           province: 'CA',
                                           city: 'Beverly Hills',
                                           postal_code: '90210',
                                           name: 'topo',
                                           company: 'gigio',
                                           phone: '23232332',
                                           address1: 'via dei mille')

# Find out how much it'll be.

#response = fedex.find_rates(origin, destination, packages)

#rates = response.rates.sort_by(&:price).collect {|rate| [rate.service_name, rate.price]}

#puts rates
options = {service_type: 'FIRST_OVERNIGHT', test: true}


packages = [
  ActiveShipping::Package.new(100, # 100 grams
                              [93, 10], # 93 cm long, 10 cm diameter
                              cylinder: true), # cylinders have different volume calculations

  ActiveShipping::Package.new(7.5 * 16, # 7.5 lbs, times 16 oz/lb.
                              [15, 10, 4.5], # 15x10x4.5 inches
                              units: :imperial) # not grams, not centimetres
]
response = fedex.find_rates(origin, destination, packages, options)
puts response.success?
puts response.message
#puts response.rates
#response.rates.each do |rate|
#                            puts rate.package_rates
#end
response.estimates.each do |estimate|
   puts estimate.total_price
   puts estimate.service_code
end


packages = [
  ActiveShipping::Package.new(100, # 100 grams
                              [93, 10], # 93 cm long, 10 cm diameter
                              cylinder: true) # cylinders have different volume calculations
]
#
# https://github.com/Shopify/active_shipping/blob/master/lib/active_shipping/label.rb
options[:group_package_count] = 1
response = fedex.create_shipment(origin, destination, packages, options)
tn = nil
response.labels.each do |label|
   tn = label.tracking_number
   puts "tn: #{tn}"
   #puts "tn: #{label.img_data}"

   if !label.img_data.nil?
      file = File.new("test.png", "wb")
      file.write(label.img_data)
      file.close
   end
end

#require 'active_shipping'
pdf = Prawn::Document.new(:page_size => 'A4')
pdf.stroke_axis
pdf.stroke do
   # cornice esterna
   pdf.line [0, 0], [520, 0]
   pdf.line [0, 770], [520, 770]
   pdf.line [0, 289], [520, 289]
   pdf.line [0, 0], [0, 770]

   # divisione box alti
   pdf.line [260, 500], [260, 770]
   pdf.line [260, 0], [260, 289]

   pdf.line [0, 289], [520, 289]
   pdf.line [0, 500], [520, 500]

   pdf.line [0, 680], [260, 680]
   pdf.line [0, 590], [520, 590]

   pdf.line [520, 0], [520, 770]

   #verticali centro
   # 1,95
   # 3,9
   # 7,9
   # 10,9
   # 12,87
   pdf.line [105, 289], [105, 500]
   pdf.line [170, 289], [170, 500]
   pdf.line [290, 289], [290, 500]
   pdf.line [380, 289], [380, 500]
   pdf.line [440, 289], [440, 500]

   #alto sx 1° vert
   pdf.bounding_box [5, 765], :width => 245, :height => 85 do

      #pdf.stroke_axis
      #pdf.text "1"
      pdf.font_size 10
      pdf.text "1. Goods consigned from (Exporter's business name, address, country)"
      pdf.font_size 9
      pdf.text ""
      pdf.text "GARDELLI SPECIALTY COFFEES s.r.l."
      pdf.text "VIA GRANDE 260"
      pdf.text "47032 BERTINORO FC"
      pdf.text "ITALY"
      pdf.text "Tax ID: IT04373480401"
   end

   #alto sx 2° vert
   pdf.bounding_box [5, 675], :width => 245, :height => 85 do
      pdf.font_size 10
      pdf.text "2. Goods consigned to (Consignee's name, address, country)"
      #pdf.stroke_axis
      #pdf.text "2"
   end

   #alto sx 3° vert
   pdf.bounding_box [5, 585], :width => 245, :height => 85 do
      pdf.text "3. Means of transport and route (as far as known)"
      pdf.text "Express courier - airplane - "
      #pdf.stroke_axis
      #pdf.text "3"
   end

   #alto dx 1° vert
   pdf.bounding_box [265, 765], :width => 245, :height => 175 do

      pdf.text "Reference No\n\n", :inline_format => true
      pdf.font_size 10
      pdf.font "Times-Roman", :style => :normal, :align => :center
      pdf.text "GENERALISED SYSTEM OF PREFERENCES CERTIFICATE OF ORIGIN" , :inline_format => true, :align => :center
      pdf.text "(Combined declaration and certificate)", :inline_format => true, :align => :center

      pdf.text "FORM A\n\n", :inline_format => true, :align => :center

      pdf.text "Issued in  ITALY\n\n", :inline_format => true

      pdf.text "(country)", :inline_format => true , :align => :center
      #pdf.stroke_axis
      #pdf.text "4"
   end

   #alto dx 2° vert
   pdf.bounding_box [265, 585], :width => 284, :height => 85 do
      pdf.text "4. For official use"
      pdf.text "COMMERCIAL"
      #pdf.stroke_axis
      #pdf.text "5"
   end


   pdf.bounding_box [5, 495], :width => 100, :height => 206 do
      #  pdf.stroke_axis
      pdf.text "5. Item number"
      #pdf.text "6"
   end

   pdf.bounding_box [110, 495], :width => 60, :height => 206 do
      # pdf.stroke_axis
      pdf.text "6. Marks and number of packages"
      #pdf.text "7"
   end

   pdf.bounding_box [175, 495], :width => 100, :height => 206 do
      # pdf.stroke_axis
      pdf.text "7. Number and kind of packages, description of goods\nRoasted coffee", :inline_format => :true
         #pdf.text "8"
   end

   pdf.bounding_box [295, 495], :width => 85, :height => 206 do
      # pdf.stroke_axis
      text = %{8. Origin criterion

PSR
Goods satisfying the product-specific rules

HS code: 0901.21.00
      }
      pdf.text text


         #pdf.text "9"
   end

   pdf.bounding_box [385, 495], :width => 50, :height => 206 do
      # pdf.stroke_axis
      pdf.text "9. Gross weight"
         #pdf.text "10"
   end

   pdf.bounding_box [445, 495], :width => 70 , :height => 206 do
      #pdf.stroke_axis
      pdf.text "10. Number and date of invoices"
         #pdf.text "11"
   end




   pdf.bounding_box [5, 284], :width => 250 , :height => 284 do
      #pdf.stroke_axis
      pdf.font_size 10
      pdf.font "Times-Roman", :style => :normal, :align => :left
      pdf.text "11. Certification", :inline_format => true
      pdf.text "   It is hereby certified, on the basis of control carried out, that the declaration by the exporter is correct.", :inline_format => true
      pdf.move_cursor_to(30)
      pdf.text "Place and date, signature and stamp of certifying authority", :inline_format => true, :align => :center
      #pdf.text "12"
   end




   pdf.bounding_box [265, 284], :width => 255 , :height => 284 do
      pdf.font_size 10
      pdf.font "Times-Roman", :style => :normal, :align => :left
      pdf.text "12. Declaration by the exporter", :inline_format => true
      pdf.text "The undersigned hereby declares that the above details and statements are correct; that all the goods were", :inline_format => true

      pdf.move_down(20)
      pdf.text "produced in ITALY", :inline_format => true
      pdf.text "(country)", :inline_format => true, :align => :center

      pdf.move_down(20)
      pdf.text "and that they comply with the origin requirements specified for those goods in the Generalised System of Preferences for goods exported to", :inline_format => true
      pdf.move_down(50)

      pdf.text "(importing country)", :inline_format => true, :align => :center
      pdf.move_cursor_to(30)
      pdf.text "Place and date, signature of authorized signatory", :inline_format => true, :align => :center
      #pdf.stroke_axis
      #pdf.text "13"
   end
end
#7,95  / 21.2 * 770
# 13,79   / 21.2 * 770
pdf.render_file "full_template.pdf"

return


packages = [
    ActiveShipping::Package.new(7.5 * 16, # 7.5 lbs, times 16 oz/lb.
                                [15, 10, 4.5], # 15x10x4.5 inches
                                units: :imperial) # not grams, not centimetres
]
#
# https://github.com/Shopify/active_shipping/blob/master/lib/active_shipping/label.rb
options[:master_tracking_id] = tn
options[:group_package_count] = 2
response = fedex.create_shipment(origin, destination, packages, options)
response.labels.each do |label|
   puts "tn: #{label.tracking_number}"
   #puts "tn: #{label.img_data}"

   if !label.img_data.nil?
      file = File.new("test1.png", "wb")
      file.write(label.img_data)
      file.close
   end
end
#https://stackoverflow.com/questions/14040137/fedex-api-shipping-label-multiple-package-shipments

#    
#
#    
#
#
#
#
#
#
#
#
#
#


=begin
total_weight = 0
masterCust = Customer.where("master = 1")
xml = Builder::XmlMarkup.new(:indent => 2, :margin => 0)
xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8" # Or whatever your requirements are
   xml.tag!("req:ShipmentRequest", {"xmlns:req" => "http://www.dhl.com", "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xsi:schemaLocation" => "http://www.dhl.com ship-val-global-req.xsd", "schemaVersion" => "6.2"}) do

      xml.Request {
         xml.ServiceHeader {
            xml.MessageTime "2017-12-29T09:30:47-05:00"
            xml.MessageReference "1234567890123456789012345678901"
            xml.SiteID "rubensga"
            xml.Password "3VaMNRCn5z"
         }
         xml.MetaData {
            xml.SoftwareName  "XMLPI"
            xml.SoftwareVersion "6.2"
         }
      }
      xml.NewShipper "N"
      xml.LanguageCode "en"
      xml.PiecesEnabled "Y"
      xml.Billing {
         xml.ShipperAccountNumber "106439867"
         xml.ShippingPaymentType "S"
         xml.BillingAccountNumber "106439867"
         xml.DutyPaymentType "R"
      }
      xml.Consignee {
         xml.CompanyName "Test cp"
         xml.AddressLine "13, 2948, Technicka"
         xml.AddressLine ""
         xml.AddressLine ""
         xml.City "Brno"
         xml.PostalCode "616 00"
         xml.CountryCode "CZ"
         xml.CountryName "Czech Republic"
         xml.Contact {
            xml.PersonName "Marco Lami"
            xml.PhoneNumber "+420053622564"
         }
      }
      xml.Reference {
         xml.ReferenceID "GSC6345"
      }
      xml.ShipmentDetails {
         xml.NumberOfPieces 1
         xml.Pieces {
            xml.Piece {
               xml.PackageType "EE"
               xml.Width 2
               xml.Height 2
               xml.Depth 2

            }
         }
         xml.Weight 0.5
         xml.WeightUnit "K"
         xml.GlobalProductCode "W"
         xml.LocalProductCode "W"
         xml.Date "2019-04-17"
         xml.Contents "ROASTED COFFEES"
         xml.DimensionUnit "C"
         xml.PackageType "EE"
         xml.IsDutiable "N"
         xml.CurrencyCode "EUR"

      }
      xml.Shipper {
         xml.ShipperID 106439867
         xml.CompanyName masterCust.description
         #  106439867 <= 30 kg
         # > 30kg 106798643
         xml.RegisteredAccount 106439867
         xml.AddressLine masterCust.address
         xml.AddressLine masterCust.address_optional
         xml.AddressLine masterCust.address_optional1
         xml.AddressLine ""
         xml.City "Bertinoro"
         xml.PostalCode 47032
         xml.CountryCode "IT"
         xml.CountryName "Italy"
         xml.Contact {
            xml.PersonName "Gardelli Specialty Coffees"
            xml.PhoneNumber "+39 0543721136"
            xml.Email "support@gardellicoffee.com"

         }

      }
      xml.LabelImageFormat "PDF"
      xml.RequestArchiveDoc "N"
      xml.Label {
         xml.LabelTemplate "6X4_PDF"
      }
   end

puts xml.target!

=begin
ar1 = ["X", "c1"]
ar2 = ["X", "c2"]
ar3 = ["X", "c3"]
ar4 = ["X", "c4"]

ar_1_2 = ar1.push(*ar2)
ar_3_4 = ar3.push(*ar4)

ar_rows = []
ar_rows.push(ar_1_2)
ar_rows.push(ar_3_4)
 puts ar_rows.to_s
exit(0)


def wrap(s, width=78)
   s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
end


testo = "Important: Since version 1.0.0 the extensions of the String class will be only available when explicitely loaded via"
testo_div = (wrap testo,20).split("\n")
puts testo_div
puts testo_div.length
=end

#puts Date::MONTHNAMES[Date.today.month]
#puts Date::MONTHNAMES[Date.today.prev_month.month]

# order_ids ='888,19'
# ar = order_ids.split(',')
# p ar
# p ar[0]
#
# order_ids ='21'
# ar = order_ids.split(',')
# p ar
# p ar[0]


=begin


=end