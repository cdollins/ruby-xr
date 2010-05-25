class EventPointEater

  def EventPointEater.eat_header(build_dir)
    puts "+#{Time.now}: Eating event header"
    elog_events = {}
    base = get_base(build_dir)
    get_elog_events(build_dir).each do |x,y|
     elog_events[x+base] = y
    end
    return elog_events
  end
  
  def EventPointEater.get_base(build_dir)
    base_name = "IFMIB_EVENT_BASE"
    rel_base = "infra/elib/include/elog_base.h"
    elib_base = "#{build_dir}/#{rel_base}"
    File.new(elib_base, "r").each do |line|
      match = /\#define\s+(\w+)\s+(\d+)/.match(line)
      if !match.nil? 
        return match[2].to_i if match[1] == base_name
      end
    end
  end

  def EventPointEater.get_elog_events(build_dir)
    points = "snmp/mibs/ifmib/include/ifmib_elog_points.h"
    event_ids = Array.new
    file = "#{build_dir}/#{points}"
    File.new(file, "r").each do |line|
      match = /^\#define\s+(\w+)\s+EV_NUM\((\d+)\)/.match(line)
      if !match.nil?     
        event_ids.push [match[2].to_i, match[1]]
      end
    end
    return event_ids
  end
end
