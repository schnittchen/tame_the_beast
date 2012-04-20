require 'tame_the_beast/reg_entry'
require 'tame_the_beast/stub'

module TameTheBeast
  class Armory
    def initialize
      @registry = {}
    end

    class ChainedDSLObject
      def initialize(reg_entry)
        @reg_entry = reg_entry
      end

      def post_inject_into(&block)
        @reg_entry.post_inject_block = block
      end
    end

    def register(slot, options = {}, &block)
      using = options.delete(:using) || []
      reg_entry = _register(slot, using, block)
      return ChainedDSLObject.new reg_entry
    end

    def inject(hash_like)
      hash_like.each do |slot, object|
        block = lambda { object }
        _register(slot, [], block)
      end
      return self
    end

    def complete?
      @registry.each do |slot, entry|
        entry.dependent_slots.each do |dependent_slot|
          unless @registry.key? dependent_slot
            yield dependent_slot, slot if block_given?
            return false
          end
        end
      end
      return true
    end

    def free_of_loops?
      raise Incomplete, "Armory is incomplete!" unless complete?

      dependency_chains = @registry.keys.map &method(:Array)

      until dependency_chains.empty?
        dependency_chains = dependency_chains.map do |chain|
          chain_begin, chain_end = chain.first, chain.last

          @registry[chain.last].dependent_slots.map do |dependent_slot|
            if dependent_slot == chain_begin
              yield chain if block_given?
              return false
            end

            chain + [dependent_slot]
          end

        end.reduce([], :+)
      end
      return true
    end

    def resolve(options = {})
      inject_dependent_reg_entries

      assert_complete_and_free_of_loops

      #do the actual resolution
      resolve_for = Array(options[:for]).map &:to_sym
      #return magic hash here
      resolution = Hash[resolve_for.map { |key| [key, @registry[key].value] }]

      #remove unused entries
      @registry.values.reject(&:constructed?).each { |reg_entry| @registry.delete reg_entry.key }

      #call post_inject_blocks
      component_hash = Container.from_reg_entries @registry.values
      @registry.values.map(&:post_inject_block).compact.each do |post_inject_block|
        post_inject_block.call(component_hash)
      end

      @registry.clear

      return resolution
    end

    private

    def _register(slot, using, block)
      slot = slot.to_sym
      using = Array(using).map &:to_sym
      block = block_or_default_for_slot slot, block

      reg_entry = RegEntry.new :slot => slot, :constructor => block, :dependent_slots => using
      @registry[slot] = reg_entry
      return reg_entry
    end

    def block_or_default_for_slot(key, block)
      return block || lambda do
        Stub.new key.inspect
      end
    end

    def inject_dependent_reg_entries
      @registry.values.each do |reg_entry|
        reg_entry.dependent_reg_entries = reg_entry.dependent_slots.map { |slot| @registry[slot] }
      end
    end

    def assert_complete_and_free_of_loops
      complete? { |dependent_slot, slot| raise Incomplete, "No component #{dependent_slot} defined (needed by #{slot}" }
      free_of_loops? { |bad_chain| raise CircularDependency, "Circular dependency: #{bad_chain.join ' '}" }
    end

  end
end
