require File.dirname(__FILE__) + '/spec_helper'

describe "NamecheapAPI Wrapper"  do
  describe "initializating settings" do
    describe "with defaults" do
      it "should contain a username" do
        namecheap = Namecheap::Namecheap.new
        namecheap.send(:username).should == 'apiuser'
      end
      it "should contain a key" do
        namecheap = Namecheap::Namecheap.new
        namecheap.send(:key).should == 'apikey'
      end
      it "should contain a client_ip" do
        namecheap = Namecheap::Namecheap.new
        namecheap.send(:client_ip).should == '127.0.0.1'
      end
    end

    describe "with defaults overidden" do
      it "shoud contain a overidden username" do
        namecheap = Namecheap::Namecheap.new(:username => 'testuser')
        namecheap.send(:username).should == 'testuser'
      end

      it "shoud contain a key" do
        namecheap = Namecheap::Namecheap.new(:key => 'testkey')
        namecheap.send(:key).should == 'testkey'
      end
      it "shoud contain a client_ip" do
        namecheap = Namecheap::Namecheap.new(:client_ip => '66.11.22.44')
        namecheap.send(:client_ip).should == '66.11.22.44'
      end
    end
  end
end