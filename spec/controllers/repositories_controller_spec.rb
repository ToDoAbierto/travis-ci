require 'spec_helper'

describe RepositoriesController do
  describe 'GET :index returns a list of repositories' do
    before(:each) { Scenario.default }

    context 'in json' do
      it 'ordered by last build started date' do
        get(:index, :format => :json)

        response.should be_success
        result = ActiveSupport::JSON.decode(response.body)
        result.count.should == 2
        result.first['slug'].should  == 'svenfuchs/minimal'
        result.second['slug'].should == 'josevalim/enginex'
      end

      it 'filtered by owner name' do
        get(:index, :owner_name => 'svenfuchs', :format => :json)

        response.should be_success
        result = ActiveSupport::JSON.decode(response.body)
        result.count.should  == 1
        result.first['slug'].should == 'svenfuchs/minimal'
      end
    end
  end

  describe 'GET :show, format json' do
    let(:repository) { Factory.create(:repository, :owner_name => 'sven', :name => 'travis-ci', :last_build_started_at => Date.today) }

    before(:each) do
      config = { 'rvm' => ['1.8.7', '1.9.2'], 'gemfile' => ['test/Gemfile.rails-2.3.x', 'test/Gemfile.rails-3.0.x'], 'env' => ['DB=sqlite3', 'DB=postgres'] }
      build = Factory.create(:build, :repository => repository, :config => config)
      build.matrix.each do |task|
        task.start!(:started_at => '2010-11-12T12:30:00Z')
        task.finish!(:status => task.config[:rvm] == '1.8.7' ? 0 : 1, :finished_at => '2010-11-12T12:30:20Z')
      end
      repository.reload
    end

    it 'returns info about repository in json format' do
      get :show, :owner_name => 'sven', :name => 'travis-ci', :format => 'json'

      ActiveSupport::JSON.decode(response.body).should == {
       'id' => repository.id,
       'slug' => 'sven/travis-ci',
       'last_build_finished_at' => '2010-11-12T12:30:20Z',
       'last_build_id' => repository.last_build_id,
       'last_build_number' => '1',
       'last_build_started_at' => '2010-11-12T12:30:00Z',
       'last_build_status' => 1
      }
    end

    context 'with parameter rvm:1.8.7' do
      it 'returns last build status passing' do
        get :show, :owner_name => 'sven', :name => 'travis-ci', :format => 'json', :rvm => '1.8.7'
        json_response['last_build_status'].should == 0
      end
    end

    context 'with parameter rvm:1.9.2' do
      it 'return last build status failing' do
        get :show, :owner_name => 'sven', :name => 'travis-ci', :format => 'json', :rvm => '1.9.2'
        json_response['last_build_status'].should == 1
      end
    end

    context 'with parameters rvm:1.8.7 and gemfile:test/Gemfile.rails-2.3.x' do
      it 'return last build status passing' do
        get :show, :owner_name => 'sven', :name => 'travis-ci', :format => 'json', :rvm => '1.8.7', :gemfile => 'test/Gemfile.rails-2.3.x'
        json_response['last_build_status'].should == 0
      end
    end

    context 'with parameters rvm:1.9.2 and gemfile:test/Gemfile.rails-3.0.x' do
      it 'return last build status failing' do
        get :show, :owner_name => 'sven', :name => 'travis-ci', :format => 'json', :rvm => '1.9.2', :gemfile => 'test/Gemfile.rails-2.3.x'
        json_response['last_build_status'].should == 1
      end
    end

    context 'with parameters rvm:1.8.7, gemfile:test/Gemfile.rails-2.3.x, and env:DB=postgres passed' do
      it 'return last build status passing' do
        get :show, :owner_name => 'sven', :name => 'travis-ci', :format => 'json', :rvm => '1.8.7', :gemfile => 'test/Gemfile.rails-2.3.x', :env => 'DB=postgres'
        json_response['last_build_status'].should == 0
      end
    end

    context 'with parameters rvm:1.9.2, gemfile:test/Gemfile.rails-2.3.x, and env:DB=postgres passed' do
      it 'return last build status failing' do
        get :show, :owner_name => 'sven', :name => 'travis-ci', :format => 'json', :rvm => '1.9.2', :gemfile => 'test/Gemfile.rails-2.3.x', :env => 'DB=postgres'
        json_response['last_build_status'].should == 1
      end
    end

    context 'with parameters rvm:perl' do
      it 'return last build status for the parent build' do
        get :show, :owner_name => 'sven', :name => 'travis-ci', :format => 'json', :rvm => 'perl'
        json_response['last_build_status'].should == 1
      end
    end
  end

  describe 'GET :show, format xml (schema: not specified)' do
    let(:repository) { Factory.create(:repository, :owner_name => 'sven', :name => 'travis-ci', :last_build_started_at => Date.today) }

    before(:each) do
      config = { 'rvm' => ['1.8.7', '1.9.2'], 'gemfile' => ['test/Gemfile.rails-2.3.x', 'test/Gemfile.rails-3.0.x'], 'env' => ['DB=sqlite3', 'DB=postgres'] }
      build = Factory.create(:build, :repository => repository, :config => config)
      build.matrix.each do |task|
        task.start!(:started_at => '2010-11-12T12:30:00Z')
        task.finish!(:status => task.config[:rvm] == '1.8.7' ? 0 : 1, :finished_at => '2010-11-12T12:30:20Z')
      end
      repository.reload
    end

    it 'return info about repository in xml format' do
      get :show, :owner_name => 'sven', :name => 'travis-ci', :format => 'xml'

      xml_response.should == {
        'repository' => {
          'id'                     => { '__content__' => '1' },
          'slug'                   => { '__content__' => 'sven/travis-ci' },
          'last_build_id'          => { '__content__' => '1' },
          'last_build_number'      => { '__content__' => '1' },
          'last_build_status'      => { '__content__' => '1' },
          'last_build_started_at'  => { '__content__' => '2010-11-12T12:30:00Z' },
          'last_build_finished_at' => { '__content__' => '2010-11-12T12:30:20Z' },
        }
      }
    end
  end

  describe 'GET :show, format xml (schema: cctray)' do
    before(:each) do
      Factory(:repository, :owner_name => 'sven', :name => 'travis-ci', :last_build_started_at => Date.today)
    end

    it 'returns info about repository in CCTray (CruiseControl) XML format' do
      get :show, :owner_name => 'sven', :name => 'travis-ci', :format => 'xml', :schema => 'cctray'
      response.should render_template('show.cctray')
    end
  end

  describe 'GET :show, format xml (schema: unknown)' do
    before(:each) do
      Factory(:repository, :owner_name => 'sven', :name => 'travis-ci', :last_build_started_at => Date.today)
    end

    it 'does not attempt to render unsupported XML schemas' do
      get :show, :owner_name => 'sven', :name => 'travis-ci', :format => 'xml', :schema => 'somerandomschema'
      response.should_not render_template('show.somerandomschema')
    end
  end

  describe 'GET :show, format png' do
    before(:each) do
      controller.stubs(:render)
    end

    def get_png(repository, params = {})
      lambda { get :show, params.merge(:owner_name => repository.owner_name, :name => repository.name, :format => 'png') }
    end

    describe 'without a branch parameter' do
      it '"unknown" when the repository does not exist' do
        repository = Repository.new(:owner_name => 'does not', :name => 'exist')
        get_png(repository).should serve_status_image('unknown')
      end

      it '"unknown" when it only has a build that is not finished' do
        repository = Factory(:running_build).repository
        get_png(repository).should serve_status_image('unknown')
      end

      it '"failing" when the last build has failed' do
        repository = Factory(:broken_build).repository
        get_png(repository).should serve_status_image('failing')
      end

      it '"passing" when the last build has passed' do
        repository = Factory(:successfull_build).repository
        get_png(repository).should serve_status_image('passing')
      end

      it '"stable" when there is a running build but the previous one has passed' do
        repository = Factory(:successfull_build).repository
        Factory(:build, :repository => repository, :state => 'started')
        get_png(repository).should serve_status_image('passing')
      end
    end

    describe 'with a branch parameter' do
      it '"unknown" when the repository does not exist' do
        repository = Repository.new(:owner_name => 'does not', :name => 'exist')
        get_png(repository, :branch => 'master').should serve_status_image('unknown')
      end

      it '"unknown" when it only has a build that is not finished' do
        repository = Factory(:running_build).repository
        get_png(repository, :branch => 'master').should serve_status_image('unknown')
      end

      it '"failing" when the last build has failed' do
        repository = Factory(:broken_build).repository
        get_png(repository, :branch => 'master').should serve_status_image('failing')
      end

      it '"passing" when the last build has passed' do
        repository = Factory(:successfull_build).repository
        get_png(repository, :branch => 'master').should serve_status_image('passing')
      end

      it '"passing" when there is a running build but the previous one has passed' do
        repository = Factory(:successfull_build).repository
        Factory(:build, :repository => repository, :state => 'started')
        get_png(repository, :branch => 'master').should serve_status_image('passing')
      end
    end
  end
end

