require File.dirname(__FILE__) + '/helper'

describe Namecheap do
  before { reset_config }

  context "with default config" do
    subject { Namecheap.config }

    its(:username) { should be_nil }
    its(:key) { should be_nil }
    its(:client_ip) { should be_nil }
    its(:endpoint) { should be_nil }
  end

  describe '.configure' do
    it 'should set the api key' do
      expect {
        Namecheap.configure do |config|
          config.key = 'the_apikey'
        end
      }.to change { Namecheap::Config.key }.to('the_apikey')
    end

    it 'should set the username' do
      expect {
        Namecheap.configure do |config|
          config.username = 'the_username'
        end
      }.to change { Namecheap::Config.username }.to('the_username')
    end

    it 'should set the client_ip' do
      expect {
        Namecheap.configure do |config|
          config.client_ip = 'the_client_ip'
        end
      }.to change { Namecheap::Config.client_ip }.to('the_client_ip')
    end

    it 'should set the endpoint' do
      expect {
        Namecheap.configure do |config|
          config.endpoint = 'the_endpoint'
        end
      }.to change { Namecheap::Config.endpoint }.to('the_endpoint')
    end
  end
end
