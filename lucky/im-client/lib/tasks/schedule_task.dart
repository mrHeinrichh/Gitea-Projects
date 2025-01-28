abstract class ScheduleTask {
  final int delay;
  final isPeriodic;
  int count = 0;
  bool isExecuting = false;
  bool finished = false;

  ScheduleTask(this.delay, this.isPeriodic){
    reset();
  }

  countdown() async {
    count--;
    if(count <= 0 && !finished){
      if(!isExecuting){
        isExecuting = true;
        execute();
      }
      if(!isPeriodic){
        finished = true;
      }
      reset();
    }
  }

  reset(){
    count = (delay ~/ 100) != 0?(delay ~/ 100): 1;
    isExecuting = false;
  }

  execute();
}
