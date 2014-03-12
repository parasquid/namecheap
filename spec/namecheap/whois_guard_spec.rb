require 'helper'

describe Namecheap::Whois_Guard do
  it 'should initialize' do
    Namecheap::Whois_Guard.new
  end

  it 'should be already initialized from the Namecheap namespace' do
    Namecheap.whois_guard.should_not be_nil
  end
end
