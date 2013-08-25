require 'csv'
require 'securerandom'
require 'logger'
require 'net/http'

require 'pp'

LOGGER = Logger.new(STDERR)
LOGGER.formatter = proc do |severity, datetime, progname, msg|
  "#{severity}: #{msg}\n"
end

ENDPOINT = "http://localhost:3030/ds/query"

class SPARQLRunner
  
  def initialize(query_file, endpoint)
    @query_file = query_file
    @endpoint = endpoint
  end
  
  def run
    endpoint_uri = URI.parse(@endpoint)
    http = Net::HTTP.new(endpoint_uri.host, endpoint_uri.port)
    request = Net::HTTP::Post.new(endpoint_uri.request_uri)
    request.initialize_http_header({"Accept" => "text/csv"})
    query = File.open(@query_file).read
    args = {"query" => query}
    request.set_form_data(args)
    response = http.request(request)
    result = response.body
    
    csv_array = CSV.parse(result)
    return convert_csv_array(CSV.parse(result))
  end
  
  def array_to_hash(array, keys)
    hash = Hash.new
    array.each_index do |index|
      key = keys[index]
      hash[key] = array[index] if array[index]
    end
    return hash
  end

  def convert_csv_array(csv_array)
    if (csv_array.length > 1)
      result_hash = Hash.new
      header = csv_array[0]
      csv_array = csv_array[1..csv_array.length-1]
      hash_array = csv_array.map {|x| array_to_hash(x, header)}
      result_hash["keys"] = header
      result_hash["results"] = hash_array
      return result_hash
    else
      return nil
    end
  end

end


class ViewQuery
  
  attr_writer :binding
  attr_reader :required
  
  def initialize(label, query_template, variable, required)
    @label = label
    @query_file = query_template
    @variable = variable
    @required = required
  end
  
  def create_temp_query
    code = File.read(@query_file)
    code.gsub!(@variable, @binding)
    filename = ("/tmp/sparql_validate_#{SecureRandom.hex}")
    file = File.open(filename, "w")
    file.puts(code)
    file.close
    return filename
  end

  def perform
    instantiated_query = self.create_temp_query
    runner = SPARQLRunner.new(instantiated_query, ENDPOINT)
    result = runner.run
    return result
  end
  
  def to_s
    return "<#{@label} (#{@query_file})>"
  end

end

class EntityTest
  
  attr_reader :entity_query, :view_queries
  
  def initialize(entity_query, view_queries)
    @entity_query = entity_query
    @view_queries = view_queries
  end
  
  def perform
    summary = Hash.new
    summary.default = 0
    entities = get_entities
    entities.each do |entity|
      LOGGER.info("view queries for <#{entity}>")
      @view_queries.each do |query|
        query.binding = entity
        result = query.perform
        message = "\t" + query.to_s + ": "
        if (result)
          message = message + "#{result['results'].count} results"
          summary[query.to_s] += 1
          LOGGER.info(message)
        else
          message = message + "No results found in <#{entity}>"
          if (query.required)
            LOGGER.error(message)
          else
            LOGGER.warn(message)
          end
        end
      end
      LOGGER.info("---------------------")
    end
    return summary
  end
  
  def get_entities
    runner = SPARQLRunner.new(@entity_query, ENDPOINT)
    if (result = runner.run)
      if (result["keys"].length > 1)
        raise SPARQLValidationError, "'#{@entity_query}' has more than one key!"
      end
      if (entities = result["results"])
        key = result["keys"][0]
        return entities.map { |x| x[key] }
      end
    else
      raise "No entities found for '#{@entity_query}'!"
    end
  end
  
end

class ConferenceTest < EntityTest
  
  def get_entities
    entities = super
    raise(SPARQLValidationError, "more than one conference event!") if (entities.length > 1)
    return entities
  end
  
  def perform
    super
    
    LOGGER.info("Generating overview: URIs and labels ...")
    runner = SPARQLRunner.new("queries/uris_and_labels.rq", ENDPOINT)
    results = runner.run
    results['results'].each do |result|
      LOGGER.info("#{result['uri']}: #{result['label']}")
    end
    LOGGER.info("---------------------")
    
    LOGGER.info("Querying all papers ...")
    entity_query = "queries/paper_uris.rq"
    base_query = ViewQuery.new("Paper Base Data", "queries/paper_base_data.rq", "$dogfood_uri", TRUE)
    author_query = ViewQuery.new("Paper Author Data", "queries/paper_author_data.rq", "$dogfood_uri", TRUE)
    paper_test = EntityTest.new(entity_query, [base_query, author_query])
    paper_summary = paper_test.perform
    output_summary("Summary Papers:", paper_summary)
    
    LOGGER.info("Querying all people ...")
    entity_query = "queries/person_uris.rq"
    base_query = ViewQuery.new("Person Base Data", "queries/person_base_data.rq", "$dogfood_uri", TRUE)
    affiliations_query = ViewQuery.new("Person Affiliations Data", "queries/person_affiliations_data.rq", "$dogfood_uri", FALSE)
    publications_query = ViewQuery.new("Person Publications Data", "queries/person_publications_data.rq", "$dogfood_uri", FALSE)
    roles_query = ViewQuery.new("Person Roles Data", "queries/person_roles_data.rq", "$dogfood_uri", FALSE)
    person_test = EntityTest.new(entity_query, [base_query, affiliations_query, publications_query, roles_query])
    person_summary = person_test.perform
    output_summary("Summary People:", person_summary)
    
    LOGGER.info("Querying all organisations ...")
    entity_query = "queries/orga_uris.rq"
    base_query = ViewQuery.new("Organisation Base Data", "queries/orga_base_data.rq", "$dogfood_uri", TRUE)
    member_query = ViewQuery.new("Organisation Member Data", "queries/orga_member_data.rq", "$dogfood_uri", FALSE)
    orga_test = EntityTest.new(entity_query, [base_query, member_query])
    orga_summary = orga_test.perform
    output_summary("Summary Organisations:", orga_summary)
    
  end
  
  def output_summary(message, summary)
    LOGGER.info(message)
    summary.each do |query, count|
      LOGGER.info("\t#{query}: #{count}")
    end
    LOGGER.info("---------------------")
  end
  
end

class SPARQLValidationError < StandardError ; end
  

dataset_file = ARGV[0]
graph_name = ARGV[1]

# load data
command = "s-put http://localhost:3030/ds/data '#{graph_name}' #{dataset_file}"
result = `#{command}`

entity_query = "queries/conference_main_uri.rq"
base_query = ViewQuery.new("Event Base Data", "queries/conference_base_data.rq", "$dogfood_uri", TRUE)
subevents_query = ViewQuery.new("Subevents", "queries/conference_subevents.rq", "$dogfood_uri", FALSE)
paper_query = ViewQuery.new("Papers at Event", "queries/conference_papers.rq", "$dogfood_uri", FALSE)
people_query = ViewQuery.new("People at Event", "queries/conference_people.rq", "$dogfood_uri", FALSE)

conference_test = ConferenceTest.new(entity_query, [base_query, subevents_query, paper_query, people_query])
conference_test.perform

# clear graph
command = "s-update --service http://localhost:3030/ds/update 'CLEAR ALL'"
result = `#{command}`
