require File.dirname(__FILE__) + '/spec_helper'

describe "Domains"  do
  it "should instantiate"  do
    Namecheap::Domains.new(:environment => 'test')
  end
end
