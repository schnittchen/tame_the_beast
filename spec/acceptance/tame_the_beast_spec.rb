require 'tame_the_beast'

module TameTheBeast
  describe TameTheBeast do
    subject { TameTheBeast.new }

    describe ".resolve" do
      context "with registered dependencies a -> b -> c" do
        before(:each) do
          @component_hashes = {}
          subject.register(:a, :using => :b) do |c|
            @component_hashes[:a] = c
            { :item => :a }
          end
          subject.register(:b, :using => :c) do |c|
            @component_hashes[:b] = c
            { :item => :b }
          end
        end

        it "should detect that c has not been registered" do
          lambda { subject.resolve(:for => %w{a b}) }.should raise_error(described_class::Incomplete)
        end

        context "with registered dependency c -> a" do
          before(:each) { subject.register(:c, :using => :a) { 2 } }

          it "should detect circular dependency" do
            lambda { subject.resolve(:for => %w{a b c}) }.should raise_error(described_class::CircularDependency)
          end
        end

        context "with simple leaf node c" do
          before(:each) do
            subject.register(:c) do |c|
              @component_hashes[:c] = c
              { :item => :c }
            end
          end

          it "should call constructor blocks with an argument" do
            subject.resolve(:for => %w{a b c})

            @component_hashes.should have_key(:a)
            @component_hashes.should have_key(:b)
            @component_hashes.should have_key(:c)
          end

          it "should pass sparse component hash to constructor blocks" do
            subject.resolve(:for => %w{a b c})

            @component_hashes[:a].should have(1).item
            @component_hashes[:b].should have(1).item
            @component_hashes[:c].should be_empty
          end

          it "should raise BadComponent when trying to access an empty slot in a component hash" do
            subject.resolve(:for => %w{a b c})

            chash = @component_hashes[:a]
            lambda { chash.a }.should raise_error(described_class::BadComponent)
            lambda { chash.c }.should raise_error(described_class::BadComponent)
            lambda { chash.x }.should raise_error(described_class::BadComponent)

            chash = @component_hashes[:b]
            lambda { chash.a }.should raise_error(described_class::BadComponent)
            lambda { chash.b }.should raise_error(described_class::BadComponent)

            chash = @component_hashes[:c]
            lambda { chash.a }.should raise_error(described_class::BadComponent)
            lambda { chash.b }.should raise_error(described_class::BadComponent)
            lambda { chash.c }.should raise_error(described_class::BadComponent)
          end

          it "should pass component hash to constructor blocks containing the right components" do
            subject.resolve(:for => %w{a b c})

            @component_hashes[:a].b[:item].should == :b
            @component_hashes[:b].c[:item].should == :c
          end

          describe "result" do
            let(:resolution) { subject.resolve(:for => %w{a b}) }

            it "contains requested components" do
#              resolution = subject.resolve(:for => %w{a b})
              resolution.should have(2).items
              resolution[:a][:item].should == :a
              resolution[:b][:item].should == :b
            end

            it "exposes components as methods as well" do
              resolution.a.should be_equal(resolution[:a])
              resolution.b.should be_equal(resolution[:b])
            end
          end

          describe ".inject" do
            it "is chainable" do
              subject.inject({}).should be_equal(subject)
            end
          end

          describe "effect of .inject" do
            before(:each) do
              subject.inject :injected => 'injected'
            end

            it "allows me to resolve for injected objects" do
              resolution = subject.resolve(:for => %w{injected})

              resolution.should have_key(:injected)
              resolution[:injected].should == 'injected'
            end

            it "allows me to use injected object for injecting into another slot object" do
              subject.register(:x, :using => :injected) do |c|
                @component_hashes[:x] = c
                "x"
              end
              subject.resolve :for => :x

              chash = @component_hashes[:x]
              chash.should have_key(:injected)
              chash[:injected].should == "injected"
            end
          end
        end

        context "with leaf node c subject to post injection" do
          before(:each) do
            subject.register(:c) do |c|
              @component_hashes[:c] = c
              { :item => :c }
            end.post_inject_into { |c| @component_hashes[:c_post] = c }
          end

          it "should invoke post_inject_into block with an argument" do
            subject.resolve(:for => %w{a})

            @component_hashes.should have_key(:c_post)
          end

          it "should invoke post_inject_into block with sparse component hash" do
            subject.resolve(:for => %w{a})

            @component_hashes[:c_post].should have(3).items
          end

          it "should invoke post_inject_into block with component hash containing needed components" do
            subject.resolve(:for => %w{a})

            chash = @component_hashes[:c_post]
            chash[:a][:item].should == :a
            chash[:b][:item].should == :b
            chash[:c][:item].should == :c
          end

          context "with detached node d" do
            before(:each) do
              subject.register(:d, :using => :a) do |c|
                @component_hashes[:d_post] = c
                { :item => :d }
              end
            end

            it "should not invoke constructor block for d" do
              subject.resolve(:for => :a)

              @component_hashes.should_not have_key(:d_post)
              @component_hashes[:b].c[:item].should == :c
            end

            it "should not keep d in component hash passed to c's post inject block" do
              subject.resolve(:for => :a)

              chash = @component_hashes[:c_post]
              chash.should have(3).items
              lambda { chash.d }.should raise_error(described_class::BadComponent)
            end
          end
        end
      end
    end

    describe "stubbing" do
      before(:each) do
        subject.register(:a)
      end

      it "should pass component hash to constructor blocks containing the right components" do
        resolution = subject.resolve(:for => :a)
        resolution[:a].class.should == Stub
        lambda { resolution[:a].some_method }.should raise_error(described_class::StubUsedError)
      end
    end

    describe "render_dependencies" do
      context "with dependencies a -> b -> c, a -> d" do
        before(:each) do
          subject.register(:a, :using => %w{b d})
          subject.register(:b, :using => :c)
          subject.register(:c)
          subject.register(:d)
        end

        let(:dependencies) { subject.render_dependencies(:format => :hash) }

        it "gives me a nice hash with dependencies" do
          keys = dependencies.keys
          keys.sort_by(&:to_s).should == [:a, :b, :c, :d]

          dependencies.each_value.sort_by(&:to_s)

          dependencies[:a].should == [:b, :d]
          dependencies[:b].should == [:c]
          dependencies[:c].should be_empty
          dependencies[:d].should be_empty
        end
      end
    end

    describe "marking for resolution" do
      describe ".resolve_for" do
        before(:each) do
          subject.register(:a)
          subject.register(:b)
          subject.register(:c)
        end

        it "is chainable" do
          subject.resolve_for.should be_equal(subject)
        end

        it "has the effekt that .resolve will deliver the argument(s). pt. 1" do
          subject.resolve_for :a
          subject.resolve.keys.should == [:a]
        end

        it "has the effekt that .resolve will deliver the argument(s). pt. 2" do
          subject.resolve_for :a
          subject.resolve(:for => :b).keys.sort_by(&:to_s).should == [:a, :b]
        end

        it "has the effekt that .resolve will deliver the argument(s). pt. 3" do
          subject.resolve_for *%w{a b}
          subject.resolve.keys.sort_by(&:to_s).should == [:a, :b]
        end

        it "has the effekt that .resolve will deliver the argument(s). pt. 4" do
          subject.resolve_for %w{a b}
          subject.resolve.keys.sort_by(&:to_s).should == [:a, :b]
        end
      end

      describe ".register(:resolve => true)" do
        before(:each) do
          subject.register(:a)
          subject.register(:b, :resolve => true)
        end

        it "has the effekt that .resolve will deliver the component" do
          subject.resolve.keys.should == [:b]
        end
      end
    end
  end
end
