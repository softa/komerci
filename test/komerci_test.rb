#require 'helper'
require 'test/unit'
require 'rubygems'
require 'mocha'
#raise Rails.root

# Add your module file here
require File.dirname(__FILE__) + '/../lib/komerci'



class KomerciTest < Test::Unit::TestCase
  
  def setup ; end
  
  def test_code
    #send 1 and 30 as the second...
    assert_equal '39533272225128-917', Komerci.code(23254866,234.56,'192.168.0.1',1)
    assert_equal '144180169218577-1062', Komerci.code(23254866,123.45,'200.195.156.133',30)
    assert_equal '76543203618577-962', Komerci.code(12345678,123.45,'200.195.156.133',30)
  end

  def test_process_numpedido_errado
    Komerci.stubs(:get_config).returns({})
    params = {'NUMPEDIDO' => '12'}
    assert_raise(Komerci::OrderIdDoesntMatchException) do
      Komerci.new(11, 100, params).process
    end
  end

  def test_process_return_error
    Komerci.stubs(:get_config).returns({})
    params = {'NUMPEDIDO' => '12', 'CODRET' => '50', 'MSGRET' => 'Erro de teste'}
    exception = assert_raise(Komerci::ReturnCodeException) do
      Komerci.new(12, 100, params).process
    end
    assert_equal 'Erro de teste', exception.to_s
  end


    #NOME       TAMANHO DESCRIÇÃO
    #DATA          8    Data da transação
    #NUMPEDIDO     16   Número do Pedido                      26
    #NR_CARTAO     16   Número do Cartão mascarado            548649******4015
    #ORIGEM_BIN    3    Código de Nacionalidade do Emissor    
    #NUMAUTOR      6    Número de Autorização
    #NUMCV         9    Número do Comprovante de Venda (NSU)
    #NUMAUTENT     27   Número de Autenticação
    #NUMSQN        12   Número seqüencial único
    
  def test_process_success
    Komerci.stubs(:get_config).returns({})
    date = Date.today.strftime('%d%m%Y')
    params = {'NUMPEDIDO' => '12', 'CODRET' => '2', 'DATA' => date, 'NR_CARTAO' => '548649******4015', 'ORIGEM_BIN' => '001', 'NUMAUTOR' => '123456', 'NUMCV' => '123456789', }
    expected = {'numpedido' => '12', 'codret' => '2', 'data' => date, 'nr_cartao' => '548649******4015', 'origem_bin' => '001', 'numautor' => '123456', 'numcv' => '123456789', }
    assert_equal expected,  Komerci.new(12, 100, params).process
  end
  
  def test_confirm_invalid_transaction_data
    Komerci.stubs(:get_config).returns({})
    assert_raise(Komerci::InvalidTransactionDataException) do
      Komerci.new(12, 123, {'NUMPEDIDO' => '12'}).confirm
    end
  end

  def test_confirm_with_error
    require 'ostruct'
    Komerci.stubs(:get_config).returns(OpenStruct.new({:filiation => 123456}))
    date = Date.today.strftime('%d%m%Y')
    params = {'NUMPEDIDO' => '12', 'CODRET' => '2', 'DATA' => date, 'NR_CARTAO' => '548649******4015', 'ORIGEM_BIN' => '001', 'NUMAUTOR' => '123456', 'NUMCV' => '123456789', }

    Komerci::Server.stubs(:send_confirmation).returns({'codret' => '1'})
    
    k = Komerci.new(12, 123, params)
    k.process
    assert ! k.confirm
  end
  
  def test_confirm
    require 'ostruct'
    Komerci.stubs(:get_config).returns(OpenStruct.new({:filiation => 123456}))
    date = Date.today.strftime('%d%m%Y')
    params = {'NUMPEDIDO' => '12', 'CODRET' => '2', 'DATA' => date, 'NR_CARTAO' => '548649******4015', 'ORIGEM_BIN' => '001', 'NUMAUTOR' => '123456', 'NUMCV' => '123456789', }

    Komerci::Server.stubs(:send_confirmation).returns({:codret => '0'})
    
    k = Komerci.new(12, 123, params)
    k.process
    assert k.confirm
  end
  
  
  
#  def test_confirm
#    Komerci.stubs(:get_config).returns({})
#    date = Date.today.strftime('%d%m%Y')
#    params = {'NUMPEDIDO' => '12', 'CODRET' => '2', 'DATA' => date, 'NR_CARTAO' => '548649******4015', 'ORIGEM_BIN' => '001', 'NUMAUTOR' => '123456', 'NUMCV' => '123456789', }
#    expected = {'numpedido' => '12', 'codret' => '2', 'data' => date, 'nr_cartao' => '548649******4015', 'origem_bin' => '001', 'numautor' => '123456', 'numcv' => '123456789', }
#    assert_equal expected,  Komerci.new.confirm(12, params)
#  end


#    order = Order.new
#    assert order
#    order.expects(:id).returns(11)
#    order.expects(:state).returns()
#    order.expects(:update_attribute).with(:p1,:p2).returns(true)
#    assert_equal :in_progress, order.state
#    assert_equal :failed, order.state      
end
