require 'helper'

describe Namecheap::Domains do
  before { set_dummy_config }

  it 'should initialize' do
    Namecheap::Domains.new
  end

  it 'should be already initialized from the Namecheap namespace' do
    Namecheap.domains.should_not be_nil
  end
end
