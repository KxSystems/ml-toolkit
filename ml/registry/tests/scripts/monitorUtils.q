monitorCols:`nulls`infinity`schema`latency`psi`csi`supervised;
monitorFeatureChecks:{[k;r]
  all(type[r]~99h;
      count[r]~7;
      cols[r]~k;
      value[r]~1111110b
      )
  }[monitorCols]
monitorValueChecks:{[k;r]
  all(type[r]~99h;
      count[r]~7;
      cols[r]~k;
      key[r`nulls]~enlist`x;
      key[r`infinity]~`negInfReplace`posInfReplace;
      key[r`latency]~`avg`std;
      key[r`csi]~enlist`x;
      r[`schema]~enlist[`x]!enlist(),"f";
      r[`supervised]~()
      )
  }[monitorCols]
