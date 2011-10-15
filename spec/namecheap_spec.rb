require File.dirname(__FILE__) + '/spec_helper'

describe "NamecheapAPI Wrapper"  do
  describe "initializating settings" do

    before :each do
      Namecheap.reset
    end

    describe "with defaults" do
      it "should contain a username" do
        Namecheap.username.should == 'apiuser'
      end
      it "should contain a key" do
        Namecheap.key.should == 'apikey'
      end
      it "should contain a client_ip" do
        Namecheap.client_ip.should == '127.0.0.1'
      end
    end

    describe "with defaults overidden" do
      it "should contain an overidden key" do
        Namecheap.configure do |config|
          config.key = 'newkey'
        end

        Namecheap.key.should == 'newkey'
      end

      it "should contain an overridden username" do
        Namecheap.configure do |config|
          config.username = 'newuser'
        end

        Namecheap.username.should == 'newuser'
      end

      it "should contain an overridden client_ip" do
        Namecheap.configure do |config|
          config.client_ip = '192.168.0.1'
        end

        Namecheap.client_ip.should == '192.168.0.1'
      end
    end
  end
end