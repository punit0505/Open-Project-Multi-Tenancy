class NotFound
  F = ::File

	def initialize(path = nil, content_type = 'text/html')
		if path.nil?
		  @content = "Not found\n"
		else
		  @content = F.read(path)
		end
		@length = @content.size.to_s

		@content_type = content_type
	end

	def call(env)
	  [404, {'Content-Type' => @content_type, 'Content-Length' => @length}, [@content]]
	end
end
