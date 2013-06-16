require File.dirname(__FILE__) + '/helper'

describe "Ssl"  do
  it 'should initialize' do
    Namecheap::Ssl.new
  end

  it 'should be already initialized from the Namecheap namespace' do
    Namecheap.ssl.should_not be_nil
  end
end
