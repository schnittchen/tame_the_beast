require 'tame_the_beast/container'

module TameTheBeast
  class RegEntry
    attr_reader :key, :dependent_slots, :constructed
    attr_writer :dependent_reg_entries
    attr_accessor :post_inject_block
    alias_method :constructed?, :constructed

    def initialize(data)
      @key, @constructor, @dependent_slots = data.values_at :slot, :constructor, :dependent_slots
      @post_inject_block, @constructed = nil, false
    end

    def value
      return @value if @constructed
      @value = @constructor.call(constructor_argument).tap { @constructed = true }
    end

    private

    def constructor_argument
      Container.from_reg_entries @dependent_reg_entries
    end
  end
end