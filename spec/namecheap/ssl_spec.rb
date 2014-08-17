require 'helper'

describe Namecheap::Ssl do
  before { set_dummy_config }

  it 'should initialize' do
    Namecheap::Ssl.new
  end

  it 'should be already initialized from the Namecheap namespace' do
    Namecheap.ssl.should_not be_nil
  end

  it 'should not raise an error' do
    Namecheap.ssl.get_list
  end
end
