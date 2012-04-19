module TameTheBeast
  class Stub
    def initialize(name)
      @name = name
    end

    def method_missing(sym, *args)
      raise StubUsedError, "#{sym.inspect} invoked on component #{@name}, which is only a stub!"
    end
  end
end
