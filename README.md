# Minify Ruby

[![CI](https://github.com/koic/minifyrb/actions/workflows/test.yml/badge.svg)](https://github.com/koic/minifyrb/actions/workflows/test.yml)

A minifier of Ruby files.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'minifyrb'
```

And then execute:

```console
$ bundle install
```

Or install it yourself as:

```console
$ gem install minifyrb
```

## Usage

For execution from the command line, use `minifyrb` command:

```console
$ cat path/to/example.rb
def foo
  bar(arg, **options) do
    baz.qux
  end
end

$ minifyrb path/to/example.rb
def foo
bar(arg,**options) do baz.qux
end
end
```

You can check the command line options with `-h` or `--help`:

```console
$ minifyrb -h
Usage: minifyrb [options] [file1, file2, ...]
    -v, --version                    Output the version number.
    -o, --output <file>              Output file (default STDOUT).
```

From Ruby code, use `Minifyrb::Minifier#minify` API:

```ruby
require 'minifyrb'

source = <<~'RUBY'
  def say(name)
    puts "Hello, #{name}!"
  end
RUBY

Minifyrb::Minifier.new(source).minify # => "def say(name)puts\"Hello, \#{name}!\"\nend\n"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/koic/minifyrb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
