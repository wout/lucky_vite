require "./tags"

module Lucky
  module HTMLPage
    macro included
      include LuckyVite::Tags
    end
  end

  abstract class BaseComponent
    include LuckyVite::Tags
  end
end
