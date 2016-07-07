package org.apache.storm.flux.wrappers.bolts;

import backtype.storm.topology.BasicOutputCollector;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.topology.base.BaseBasicBolt;
import backtype.storm.tuple.Tuple;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Simple bolt that does nothing other than LOG.info() every tuple recieveed.
 *
 */
public class LogInfoBolt extends BaseBasicBolt {
    private static final Logger LOG = LoggerFactory.getLogger(LogInfoBolt.class);

    @Override
    public void execute(Tuple tuple, BasicOutputCollector basicOutputCollector) {
       LOG.info("{}", tuple);
    }

    @Override
    public void declareOutputFields(OutputFieldsDeclarer outputFieldsDeclarer) {

    }
}
