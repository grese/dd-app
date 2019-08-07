//
//  AnalyticsViewController.swift
//  App1
//
//  Created by Nilay Pal on 8/4/19.
//  Copyright © 2019 Sara Cassidy. All rights reserved.
//

import UIKit
import Charts

class AnalyticsViewController: UIViewController {

    @IBOutlet weak var barChart: BarChartView!
    @IBOutlet weak var btnClose: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        barChartUpdate()
    }
    
    @IBAction func btnCloseClicked(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    func barChartUpdate () {
        /*
        let success: Bool
        let deviceEvents: Array<Event>
        let client = APIClient.shared
        client.fetchEvents(userID: "3", deviceID: "26130984-4221-4008-8402-01008040a050", completion: (deviceEvents, success))
         */
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let events: [EventChartData] = [EventChartData(weekDate: formatter.date(from: "2019/08/01")!, eventCount: 30),
                                        EventChartData(weekDate: formatter.date(from: "2019/08/02")!, eventCount: 16),
                                        EventChartData(weekDate: formatter.date(from: "2019/08/03")!, eventCount: 12),
                                        EventChartData(weekDate: formatter.date(from: "2019/08/04")!, eventCount: 9),
                                        EventChartData(weekDate: formatter.date(from: "2019/08/05")!, eventCount: 17),
                                        EventChartData(weekDate: formatter.date(from: "2019/08/06")!, eventCount: 13),
                                        EventChartData(weekDate: formatter.date(from: "2019/08/07")!, eventCount: 11)]
        let dataSet = BarChartDataSet()
        //dataSet.colors = [.yellow]
        dataSet.label = "Number of Events"
        for (index, evt) in events.enumerated() {
            //dataSet.append(BarChartDataEntry(x: evt.weekDate.timeIntervalSince1970, y: Double(evt.eventCount)))
            dataSet.append(BarChartDataEntry(x: Double(index), y: Double(evt.eventCount)))
        }

        let data = BarChartData(dataSets: [dataSet])
        barChart.data = data
        barChart.xAxis.labelPosition = XAxis.LabelPosition.bottom
        barChart.xAxis.gridLineWidth = 0
        
        let xValuesFormatter = ChartXAxisFormatter(startDate: formatter.date(from: "2019/08/01")!)
        xValuesFormatter.dateFormatter = DateFormatter()
        barChart.xAxis.valueFormatter = xValuesFormatter
        
        //This must stay at end of function
        barChart.notifyDataSetChanged()
    }
}

class ChartXAxisFormatter: NSObject {
    var dateFormatter: DateFormatter?
    var startDate: Date
    
    init(startDate: Date) {
        self.startDate = startDate
    }
}

extension ChartXAxisFormatter: IAxisValueFormatter {
   
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let dateValue = Date(timeInterval: value * 86400, since: startDate)
        dateFormatter!.dateFormat = "MM/dd"
        return dateFormatter!.string(from: dateValue)
    }
    
}
