#53083516351-643
#530835163.051-643
# ,sn=nil
#sn||
class Komerci

  CONFIRMATION_STATUS = {
    0 => "Confirmação com sucesso",
    1 => "Já confirmada (transação já confirmada anteriormente)",
    2 => "Transação negada",
    3 => "Transação desfeita (ultrapassado o tempo disponível para confirmação)",
    4 => "Transação estornada",
    5 => "Transação estornada",
    8 => "Dados não coincidem",
    9 => "Transação não encontrada",
    88 => "Dados ausentes. Transação não pode ser concluída"
  }

  class OrderIdDoesntMatchException < StandardError; end
  class ReturnCodeException < StandardError; end
  class InvalidTransactionDataException < StandardError; end
    
  class Server
    def self.send_confirmation data
      get = data.collect { |key, value| "#{key}=#{CGI.escape(value.to_s)}" }.join("&")  
      url = "http://ecommerce.redecard.com.br/pos_virtual/confirma.asp?#{get}"
      require 'open-uri'
      open(url) do |result|
        params = CGI::parse(result.read)
        new_params = {}
        require 'iconv'
    		i = Iconv.new 'UTF-8', 'ISO-8859-1'
        params.each_pair{|k,v| new_params[k.downcase] = i.iconv(v.first) }
        return new_params
      end
    end
  end

  def self.code(filiation,total,ip,now=nil)
    s = [11,17,21,31,56,34,42,3,18,13,12,18,22,32,57,35,43,4,19,14,9,20,23,33,58,6,44,5,24,15,    62,25,34,59,37,45,6,25,16,27,63,26,35,60,38,46,7,26,17,28,14,36,2,39,47,8,29,22,55,33][now||Time.now.sec]
    pad = s < 10 ? '0' : ''
    total_i = total.to_i
    i5 = (s + total).to_i
    i6 = s + ip.size
    i7 = s * filiation.to_i
    i8 = i7.to_s.size
    "#{i7}#{i5}#{i6}-#{i8}#{pad}#{s}"
  end

  @@config = nil
  def self.get_config
    return @@config if @@config
    content = File.read("#{Rails.root}/config/komerci.yml")
    @@config = OpenStruct.new(YAML.load(content)[:komerci])
  end

  def initialize order_id, order_total, params
    @order_id, @order_total, @params = order_id, order_total, params
    if( @order_id != @params['NUMPEDIDO'].to_i )
      raise OrderIdDoesntMatchException, 'Erro ao processar pagamento'
    end
    @config = Komerci.get_config
  end

  def process

    # Transação aprovada
    #NOME       TAMANHO DESCRIÇÃO
    #DATA          8    Data da transação
    #NUMPEDIDO     16   Número do Pedido                      26
    #NR_CARTAO     16   Número do Cartão mascarado            548649******4015
    #ORIGEM_BIN    3    Código de Nacionalidade do Emissor    
    #NUMAUTOR      6    Número de Autorização
    #NUMCV         9    Número do Comprovante de Venda (NSU)
    #NUMAUTENT     27   Número de Autenticação
    #NUMSQN        12   Número seqüencial único

    # Transação não aprovada
    #NOME      TAMANHO DESCRIÇÃO
    #NUMPEDIDO     16  Número do Pedido
    #CODRET        2   Código de erro
    #MSGRET       200  Mensagem de erro

    @transaction_data = {}
    require 'iconv'
		i = Iconv.new 'UTF-8', 'ISO-8859-1'
    @params.each_pair{|k,v| @transaction_data[k.downcase] = i.iconv(v) if ! ['action','controller'].include? k }
        
    if @params['CODRET'] and @params['CODRET'].to_i > 49
      raise ReturnCodeException, @params['MSGRET']
    end

    return @transaction_data
  end


  def confirm
    raise InvalidTransactionDataException, 'Erro ao processar pagamento' unless @transaction_data
    #        :Transação      => 203,               #3    Código da transação de confirmação
#        :Transação      => 88,               #3    Código da transação de confirmação
                                              #TODO tem q ver se é 04 mesmo e colocar no config!
    data = {
        :data           => @transaction_data[:data],            #8    Data da transação
        :transorig      => '04',              #2    Código do tipo da transação original
        :parcelas       => '00',              #2    Número de parcelas da transação
        :filiacao       => @config.filiation,        #9    Filiação do estabelecimento (fornecedor)
        :distribuidor   => '',                #9    Filiação do estabelecimento (distribuidor)
#        :total          => order.total,       #15   Valor da transação
        :total          => @order_total,       #15   Valor da transação
        :numpedido      => @transaction_data[:numpedido],       #16   Número do pedido
        :numautor       => @transaction_data[:numautor],        #6    Número da autorização
        :numcv          => @transaction_data[:numcv],           #9    Número do Comprovante de Vendas
        :numsqn         => @transaction_data[:numsqn]           #12   Número seqüencial único
    }
    @confirmation_data = Komerci::Server.send_confirmation data
#    raise @confirmation_data['codret'].inspect + "!!!!!!!!!!!!"

    if @confirmation_data['codret'].to_i == 0
      true
    else
      @error = @confirmation_data['msgret']
      false
    end
  end

  attr_reader :transaction_data, :confirmation_data, :error
#  def transaction_data
#    @transaction_data
#  end
#  def confirmation_data
#    @confirmation_data
#  end


  module Helper
    ##
    # order
    #   - must be an AR instance, with a "total" method
    # card
    #   - :mastercard or :dinners

    ##
    def komerci_form order, card=:master, options={}
      @card = card
#      @card = options[:card] || :mastercard
#      @process_url = options[:process_url] || "http://softa.localhost:3000"+confirmation_store_order_path(:locale => nil)
#       'http://localhost:3000'
      @config = Komerci.get_config
      options.each{|option,value| @config.send("#{option}=",value)}
      
#      raise @config.inspect
      @order = order
      render :partial => 'komerci/form'
    end
  end

end


