require 'helper'

describe Namecheap::Users do
  it 'should initialize' do
    Namecheap::Users.new
  end

  it 'should be already initialized from the Namecheap namespace' do
    Namecheap.users.should_not be_nil
  end
end
