require 'spec_helper'

describe Otwtranslation::SourcesController, "GET index" do
  
  it "should fail if we are not authenticated" do
    get :index
    response.should_not be_success
  end

  it "should return list of sources" do
    admin_login()
    sources = mock(Array)
    Otwtranslation::Source.should_receive(:all).and_return(sources)
    get :index
    assigns[:sources] = sources
  end
end

describe Otwtranslation::SourcesController, "GET show" do
  
  it "should fail if we are not authenticated" do
    get :show, :id => 1
    response.should_not be_success
  end

  it "should return a source" do
    admin_login()
    source = mock_model(Otwtranslation::Source)
    Otwtranslation::Source.should_receive(:find).with(1).and_return(source)
    get :show, :id => 1
    assigns[:source] = source
  end
end
