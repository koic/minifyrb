# frozen_string_literal: true

require 'minifyrb/rake_task'

RSpec.describe Minifyrb::RakeTask do
  before do
    Rake::Task.clear
  end

  after do
    Rake::Task.clear
  end

  describe 'defining tasks' do
    it 'creates a minifyrb task' do
      described_class.new

      expect(Rake::Task).to be_task_defined(:minifyrb)
    end
  end
end
