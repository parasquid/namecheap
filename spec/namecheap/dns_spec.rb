require 'helper'

describe Namecheap::Dns do
  it 'should initialize' do
    Namecheap::Dns.new
  end

  it 'should be already initialized from the Namecheap namespace' do
    Namecheap.dns.should_not be_nil
  end
end
