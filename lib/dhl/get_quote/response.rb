class Dhl::GetQuote::Response
  include Dhl::GetQuote::Helper

  attr_reader :raw_xml, :parsed_xml, :error
  attr_reader :currency_code, :currency_role_type_code, :weight_charge, :total_amount, :total_tax_amount, :weight_charge_tax

  CURRENCY_ROLE_TYPE_CODES = %w[ BILLC PULCL BASEC INVCU ]
  DEFAULT_CURRENCY_ROLE_TYPE_CODE = 'BILLC'

  def initialize(xml="")
    @raw_xml = xml
    begin
      @parsed_xml = MultiXml.parse(xml)
    rescue MultiXml::ParseError => e
      @error = e
      return self
    end

    if response_indicates_error?
      @error = case response_error_condition_code.to_s
      when "100"
        Dhl::GetQuote::Upstream::ValidationFailureError.new(response_error_condition_data)
      else
        Dhl::GetQuote::Upstream::UnknownError.new(response_error_condition_data)
      end
    elsif condition_indicates_error?
      @error = Dhl::GetQuote::Upstream::ConditionError.new(condition_error_code, condition_error_message)
    else
      load_costs(DEFAULT_CURRENCY_ROLE_TYPE_CODE)
    end
  end

  def error?
    !!@error
  end

  def load_costs(currency_role_type_code=DEFAULT_CURRENCY_ROLE_TYPE_CODE)
    validate_currency_role_type_code!(currency_role_type_code)

    return if error?

    qtd_shp = [ @parsed_xml["res:DCTResponse"]["GetQuoteResponse"]["BkgDetails"]["QtdShp"] ].flatten
    qtd_s_in_ad_cur = qtd_shp.detect{|q|q["TransInd"] == "Y"}["QtdSInAdCur"]

    pricing = if x = qtd_s_in_ad_cur.detect{|q|q["CurrencyRoleTypeCode"]==currency_role_type_code}
      x
    else
      qtd_s_in_ad_cur.first
    end

    pricing.each do |k,v|
      instance_variable_set("@#{underscore(k)}".to_sym, v)
    end
  end

  def validate_currency_role_type_code!(currency_role_type_code)
    unless CURRENCY_ROLE_TYPE_CODES.include?(currency_role_type_code)
      raise Dhl::GetQuote::OptionsError,
        "'#{currency_role_type_code}' is not one of #{CURRENCY_ROLE_TYPE_CODES.join(', ')}"
    end
  end

  def offered_services
    market_services.select do
      |m| m['TransInd'].to_s == "Y" || m['MrkSrvInd'].to_s == "Y"
    end.map do |m|
      Dhl::GetQuote::MarketService.new(m)
    end.sort{|a,b| a.code <=> b.code }
  end

  def all_services
    market_services.map do |m|
      Dhl::GetQuote::MarketService.new(m)
    end.sort{|a,b| a.code <=> b.code }
  end

protected

  def response_indicates_error?
    @parsed_xml.keys.include?('ErrorResponse')
  end

  def response_error_status_condition
    @response_error_status_condition ||= @parsed_xml['ErrorResponse']['Response']['Status']['Condition']
  end

  def response_error_condition_code
    @response_error_condition_code ||= response_error_status_condition['ConditionCode']
  end

  def response_error_condition_data
    @response_error_condition_data ||= response_error_status_condition['ConditionData']
  end

  def condition_indicates_error?
    @parsed_xml["res:DCTResponse"]["GetQuoteResponse"] &&
      @parsed_xml["res:DCTResponse"]["GetQuoteResponse"].keys.include?('Note') &&
        @parsed_xml["res:DCTResponse"]["GetQuoteResponse"]["Note"].keys.include?('Condition') &&
          @parsed_xml["res:DCTResponse"]["GetQuoteResponse"]["Note"]["Condition"].is_a?(Hash)
  end

  def condition_error_code
    @parsed_xml["res:DCTResponse"]["GetQuoteResponse"]["Note"]["Condition"]["ConditionCode"]
  end

  def condition_error_message
    @parsed_xml["res:DCTResponse"]["GetQuoteResponse"]["Note"]["Condition"]["ConditionData"].strip
  end

  def market_services
    @market_services ||= begin
      srv = @parsed_xml["res:DCTResponse"]["GetQuoteResponse"]["Srvs"]["Srv"]
      a = []
      if srv.is_a? Array
        srv.each{|aa| a << aa["MrkSrv"]}
      else
        a << srv["MrkSrv"]
      end
      a.flatten
    end
      # @parsed_xml["DCTResponse"]["GetQuoteResponse"]["Srvs"]["Srv"]["MrkSrv"]
  end

end