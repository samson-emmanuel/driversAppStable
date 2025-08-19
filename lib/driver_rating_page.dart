import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // for formatting dates
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'data_provider.dart';

class StarRatingPage extends StatefulWidget {
  const StarRatingPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _StarRatingPageState createState() => _StarRatingPageState();
}

class _StarRatingPageState extends State<StarRatingPage>
    with SingleTickerProviderStateMixin {
  double selectedWeekRating = 0.0;
  int? selectedMonth; // Store selected month (null if none selected)
  List<double> weeklyRatings = [];
  List<double> monthlyRatings = [];
  bool isLoading = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    fetchRatingsForYear(); // Fetch monthly ratings initially
  }

  // Fetch ratings for all months in the current year
  Future<void> fetchRatingsForYear() async {
    setState(() {
      isLoading = true;
      monthlyRatings = [];
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final String? sapId = dataProvider.sapId; // Get sapId from DataProvider

    if (sapId == null || sapId.isEmpty) {
      // print('Error: sapId is null or empty');
      return;
    }

    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final DateTime now = DateTime.now();
    final int currentYear = now.year;

    for (int month = 1; month <= 12; month++) {
      DateTime firstDayOfMonth = DateTime(currentYear, month, 1);
      DateTime lastDayOfMonth = DateTime(currentYear, month + 1, 0);

      final String startDate = formatter.format(firstDayOfMonth);
      final String endDate = formatter.format(lastDayOfMonth);

      // print(
      //     "Fetching data for Month $month, Start Date: $startDate, End Date: $endDate");

      try {
        await dataProvider.fetchDriverRatingReport(startDate, endDate, sapId);
        final response = dataProvider.ratingResponse;
        // print(response);

        if (response != null && response['result'] != null) {
          final double rating = double.parse(
              response['result']['totalAverageRatingInStars']?.toString() ??
                  '0.0');

          setState(() {
            monthlyRatings.add(rating);
          });
        } else {
          setState(() {
            monthlyRatings.add(0.0); // Add default value if no rating
          });
        }
      } catch (e) {
        // print('Error fetching month $month rating: $e');
        setState(() {
          monthlyRatings.add(0.0); // Add default value if an error occurs
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  // Fetch ratings for all weeks in the selected month
  Future<void> fetchRatingsForMonth(int month) async {
    setState(() {
      isLoading = true;
      weeklyRatings = [];
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final String? sapId = dataProvider.sapId; // Get sapId from DataProvider

    if (sapId == null || sapId.isEmpty) {
      print('Error: sapId is null or empty');
      return;
    }

    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final DateTime now = DateTime.now();
    final int currentYear = now.year;

    DateTime firstDayOfMonth = DateTime(currentYear, month, 1);
    DateTime lastDayOfMonth = DateTime(currentYear, month + 1, 0);

    int weekCount =
        (lastDayOfMonth.difference(firstDayOfMonth).inDays ~/ 7) + 1;

    for (int week = 0; week < weekCount; week++) {
      DateTime weekStart = firstDayOfMonth.add(Duration(days: week * 7));
      DateTime weekEnd = weekStart.add(const Duration(days: 6));

      final String startDate = formatter.format(weekStart);
      final String endDate = formatter.format(weekEnd);

      // print("Fetching data for Week $week, Start Date: $startDate, End Date: $endDate");

      try {
        await dataProvider.fetchDriverRatingReport(startDate, endDate, sapId);
        final response = dataProvider.ratingResponse;
        // print(response);

        if (response != null && response['result'] != null) {
          final double rating = double.parse(
              response['result']['totalAverageRatingInStars']?.toString() ??
                  '0.0');

          setState(() {
            weeklyRatings.add(rating);
            _animationController.forward(from: 0.0); // Animate the chart update
          });
        } else {
          setState(() {
            weeklyRatings.add(0.0); // Add default value if no rating
          });
        }
      } catch (e) {
        // print('Error fetching week $week rating: $e');
        setState(() {
          weeklyRatings.add(0.0); // Add default value if an error occurs
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget buildMonthlyBarChart() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'Your Monthly Ratings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        SizedBox(
          height: 500,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BarChart(
                  BarChartData(
                    barGroups: monthlyRatings.asMap().entries.map((entry) {
                      int index = entry.key;
                      double rating = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: rating,
                            color: Colors.green,
                            width: 22,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                        showingTooltipIndicators: [],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            int monthIndex = value.toInt();
                            String monthName = DateFormat('MMM')
                                .format(DateTime(0, monthIndex + 1));
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedMonth = monthIndex + 1;
                                  fetchRatingsForMonth(selectedMonth!);
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 6.0, 0, 0),
                                child: Text(
                                  monthName,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            return Text(value.toString());
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      verticalInterval: 1,
                      drawHorizontalLine: true,
                      horizontalInterval: 1,
                      getDrawingVerticalLine: (value) {
                        return const FlLine(
                          color: Colors.grey,
                          strokeWidth: 1,
                        );
                      },
                      getDrawingHorizontalLine: (value) {
                        return const FlLine(
                          color: Colors.lightGreen,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.green),
                    ),
                    minY: 0,
                    maxY: 5,
                    barTouchData: BarTouchData(
                      enabled: false, // Disable interactions
                    ),
                    groupsSpace: 40, // Add space between bars (months)
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildWeeklyLineChart() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Text(
          'Your Weekly Ratings for ${DateFormat('MMMM').format(DateTime(0, selectedMonth!))}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 10,
        ),
        SizedBox(
          height: 500,
          child: weeklyRatings.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Card(
                        elevation: 20,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: LineChart(
                            LineChartData(
                              lineBarsData: [
                                LineChartBarData(
                                  spots: weeklyRatings
                                      .asMap()
                                      .entries
                                      .map((entry) => FlSpot(
                                          entry.key.toDouble(), entry.value))
                                      .toList(),
                                  isCurved: false,
                                  color: Colors.green,
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(show: true),
                                ),
                              ],
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      int weekIndex = value.toInt();
                                      return Text('Week ${weekIndex + 1}');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      return Text(value.toString());
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                verticalInterval: 1,
                                drawHorizontalLine: true,
                                horizontalInterval: 1,
                                getDrawingVerticalLine: (value) {
                                  return const FlLine(
                                    color: Colors.lightGreen,
                                    strokeWidth: 1,
                                  );
                                },
                                getDrawingHorizontalLine: (value) {
                                  return const FlLine(
                                    color: Colors.lightGreen,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.green),
                              ),
                              minY: 0,
                              maxY: 5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              : const Center(
                  child: Text('No ratings available for the selected month'),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedMonth == null ? 'Monthly Ratings' : 'Weekly Ratings',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        leading: selectedMonth != null
            ? Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedMonth = null;
                      weeklyRatings = [];
                    });
                  },
                ),
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              onPressed: () {
                if (selectedMonth == null) {
                  fetchRatingsForYear();
                } else {
                  fetchRatingsForMonth(selectedMonth!);
                }
              },
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loading icon
          : SingleChildScrollView(
              child: selectedMonth == null
                  ? buildMonthlyBarChart()
                  : buildWeeklyLineChart(),
            ),
    );
  }
}