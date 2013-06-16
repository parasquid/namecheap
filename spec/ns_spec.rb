require File.dirname(__FILE__) + '/helper'

describe "Ns"  do
  it 'should initialize' do
    Namecheap::Ns.new
  end

  it 'should be already initialized from the Namecheap namespace' do
    Namecheap.ns.should_not be_nil
  end
end
