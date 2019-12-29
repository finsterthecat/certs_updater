class Point
    attr_reader :x, :y

    def initialize(x, y)
        @x = x
        @y = y
    end
end

class Rect
    attr_reader :bottom_left, :top_right

    def initialize(p1, p2)
        raise ArgumentError.new("Not a rectangle") if p1.x == p2.x || p1.y == p2.y
        @bottom_left = Point.new([p1.x, p2.x].min, [p1.y, p2.y].min)
        @top_right = Point.new([p1.x, p2.x].max, [p1.y, p2.y].max)
    end

    def overlaps?(other)
        @bottom_left.x < other.top_right.x &&
            @top_right.x > other.bottom_left.x  &&
            @bottom_left.y < other.top_right.y &&
            @top_right.y > other.bottom_left.y
    end
    
    def to_s
        "Rect<(#{@bottom_left.x}, #{@bottom_left.y}):(#{@top_right.x}, #{top_right.y})>"
    end

    def self.derive_overlap(one, other)
        if one.overlaps?(other) then
            Rect.new(Point.new([other.bottom_left.x, one.bottom_left.x].max,
                                [other.bottom_left.y, one.bottom_left.y].max),
                        Point.new([other.top_right.x, one.top_right.x].min,
                                [other.top_right.y, one.top_right.y].min))
        else
            raise ArgumentError.new("Rectangles don't overlap")
        end
    end

    def self.construct(x1, y1, x2, y2)
        Rect.new(Point.new(x1, y1), Point.new(x2, y2))
    end
end

rect1 = Rect.construct(1, 1, 3, 2)
rect2 = Rect.new(Point.new(0,1), Point.new(2,3))
puts "Rect1: #{rect1}\nRect2: #{rect2}"
puts "Overlap: #{Rect.derive_overlap(rect1, rect2)}"
puts "Overlap: #{Rect.derive_overlap(Rect.construct(1,1,3,5), Rect.construct(2,2,8,4))}"
