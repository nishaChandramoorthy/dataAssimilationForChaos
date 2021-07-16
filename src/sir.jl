σ_o = 1.0
function p_y_g_x(a)
    return 1/sqrt(2π)/σ_o*exp(-0.5*a*a/σ_o/σ_o)
end
function obs(x)
    return x
end
function sir(y,x,N_thr=10)
	K = size(y)[1]
	N_p = size(x)[1]
    w = ones(N_p)./N_p
	new_pts = similar(x)
	for k = 1:K
    	for i = 1: N_p 
		    w[i] = w[i]*p_y_g_x(y[k] - obs(x[i]))
    	end
		w ./= sum(w)
	    N_eff = 1.0/sum(w.*w)
        if (N_eff < N_thr)
	        #resample
            cdfw = cumsum(w)
			new_pts .= similar(x)
            for j = 1:N_p
			    r = rand()
			    for i = 1:N_p
		    	    if cdfw[i] >= r
					    new_pts[j] = x[i]
			            break
			        end
		        end
		    end
			x .= new_pts
	    end
    end
end
						


