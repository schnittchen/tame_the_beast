require 'tame_the_beast/armory'

module TameTheBeast
  class Incomplete < RuntimeError; end
  class CircularDependency < RuntimeError; end
  class BadComponent < RuntimeError; end
  class StubUsedError < RuntimeError; end

  def self.new(*args)
    Armory.new *args
  end
end
