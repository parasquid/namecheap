require 'helper'

describe Namecheap::Transfers do
  it 'should initialize' do
    Namecheap::Transfers.new
  end

  it 'should be already initialized from the Namecheap namespace' do
    Namecheap.transfers.should_not be_nil
  end
end
