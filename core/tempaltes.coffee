template_data = {}

for filename in fs.readdirSync "#{__dirname}/core/template"
  template_name = path.basename filename, path.extname(filename)
  template_data[template_name] = fs.readFileSync("#{__dirname}/template/#{filename}").toSting()

module.exports =  template_data
