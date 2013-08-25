#!/bin/bash

echo "2001"
ruby validate.rb open-conference-data/data/iswc/swws-2001-complete.ttl "http://data.semanticweb.org/conference/swws/2001/complete" 2> results/results_2001.log
echo "2002"
ruby validate.rb open-conference-data/data/iswc/iswc-2002-complete.ttl "http://data.semanticweb.org/conference/iswc/2002/complete" 2> results/results_2002.log
echo "2003"
ruby validate.rb open-conference-data/data/iswc/iswc-2003-complete.ttl "http://data.semanticweb.org/conference/iswc/2003/complete" 2> results/results_2003.log
echo "2004"
ruby validate.rb open-conference-data/data/iswc/iswc-2004-complete.ttl "http://data.semanticweb.org/conference/iswc/2004/complete" 2> results/results_2004.log
echo "2005"
ruby validate.rb open-conference-data/data/iswc/iswc-2005-complete.ttl "http://data.semanticweb.org/conference/iswc/2005/complete" 2> results/results_2005.log
echo "2006"
ruby validate.rb open-conference-data/data/iswc/iswc-2006-complete.new.ttl "http://data.semanticweb.org/conference/iswc/2006/complete" 2> results/results_2006.log
echo "2007"
ruby validate.rb open-conference-data/data/iswc/iswc-aswc-2007-complete.new.ttl "http://data.semanticweb.org/conference/iswc-aswc/2007/complete" 2> results/results_2007.log
echo "2008"
ruby validate.rb open-conference-data/data/iswc/iswc-2008-complete.new.ttl "http://data.semanticweb.org/conference/iswc/2008/complete" 2> results/results_2008.log
echo "2009"
ruby validate.rb open-conference-data/data/iswc/iswc-2009-complete.new.ttl "http://data.semanticweb.org/conference/iswc/2009/complete" 2> results/results_2009.log
echo "2010"
ruby validate.rb open-conference-data/data/iswc/iswc-2010-complete.new.ttl "http://data.semanticweb.org/conference/iswc/2010/complete" 2> results/results_2010.log
echo "2011"
ruby validate.rb open-conference-data/data/iswc/iswc-2011-complete.new.ttl "http://data.semanticweb.org/conference/iswc/2011/complete" 2> results/results_2011.log
echo "2012"
ruby validate.rb open-conference-data/data/iswc/iswc-2012-complete.new.ttl "http://data.semanticweb.org/conference/iswc/2012/complete" 2> results/results_2012.log
echo "done!"
