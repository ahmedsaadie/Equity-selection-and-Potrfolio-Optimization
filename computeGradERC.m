function gval = computeGradERC (x)
  global Q
  n = size(Q,1) ;  

  if(size(x,1)==1)
     x = x';
  end
  
  % Insert your gradiant computations here
  % You can use finite differences to check the gradient
  
  gval = zeros(n,1); 
  
  h=1e-5;
  
  x0= x;
  
  y0= computeObjERC(x0);
  
  for i=1:n
      x=x0;
      x(i)=x(i)+2*h;
      x1= x;
      y1= computeObjERC(x1);
      gval(i,1)=(y1-y0)/(2*h);
  end
  gval;
  
end
