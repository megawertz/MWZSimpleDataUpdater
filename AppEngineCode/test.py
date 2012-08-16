import webapp2

serverFileVersion = 1
fileHash = "?hash=" + "0c939db093c6307c6adae2fb7be36740"

class MainPage(webapp2.RequestHandler):
	def get(self):
		self.response.out.write("")
		
class DownLoader(webapp2.RequestHandler):
	def get(self):
		clientFileVersion = self.request.get("v")
		if clientFileVersion and int(clientFileVersion) < serverFileVersion:
			self.redirect("/static/tux.png"+fileHash)
		else:
			self.error(204)
			
app = webapp2.WSGIApplication( [('/', MainPage),
								('/downloader', DownLoader)],
								debug=True)