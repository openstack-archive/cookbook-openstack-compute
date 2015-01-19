task default: ["test"]

task :test => [:lint, :style, :unit]

task :bundler_prep do
  mkdir_p '.bundle'
  sh %{bundle install --path=.bundle --jobs 1 --retry 3 --verbose}
end

task :berks_prep => :bundler_prep do
  sh %{bundle exec berks vendor}
end

task :lint => :bundler_prep do
  sh %{bundle exec foodcritic --epic-fail any --tags ~FC003 --tags ~FC023 .}
end

task :style => :bundler_prep do
  sh %{bundle exec rubocop}
end

task :unit => :berks_prep do
  sh %{bundle exec rspec --format documentation}
end

task :clean do
  rm_rf [
    '.bundle',
    'berks-cookbooks',
    'Gemfile.lock',
    'Berksfile.lock'
  ]
end
