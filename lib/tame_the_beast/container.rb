module TameTheBeast
  class Container < Hash
    def self.[](*args)
      new.replace Hash[*args]
    end

    def self.from_reg_entries(entries)
      self[entries.map { |re| [re.key, re.value] }]
    end

    def method_missing(sym)
      self[sym]
    end

    def [](key)
      fetch key, &method(:_bad_access)
    end

    def _bad_access(sym)
      raise BadComponent, "component #{sym} unknown or unavailable"
    end
  end
end
