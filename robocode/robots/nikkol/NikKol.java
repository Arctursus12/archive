package nikkol;
import robocode.*;
import robocode.Robot;
import static robocode.util.Utils.normalRelativeAngleDegrees;
import java.lang.Math;
import java.awt.*;

public class NikKol extends Robot{
    int count;
    double gunTurn;
    String tracking;
    public void run(){
        setBodyColor(new Color(237, 231, 230));
		setGunColor(new Color(181, 173, 172));
		setRadarColor(new Color(150, 144, 145));
		setBulletColor(new Color(224, 40, 50));
		setScanColor(new Color(255, 0, 85));
        setAdjustGunForRobotTurn(true);
        while(true){
			turnGunRight(gunTurn);
			count++;
			if (count > 2){
				gunTurn = -30;
			}
			if (count > 5){
				gunTurn = 30;
			}
			if (count > 11){
				tracking = null;
            }
        }
    }    
    public void onScannedRobot(ScannedRobotEvent e){
		if (tracking != null && !e.getName().equals(tracking)){
			return;
		}
		if (tracking == null){
			tracking = e.getName();
		}
		count = 0;
		if (e.getDistance() > 300){
			gunTurn = normalRelativeAngleDegrees(e.getBearing() + (getHeading() - getRadarHeading()));
		    turnGunRight(gunTurn); 
		    fire(3);
		}
		gunTurn = normalRelativeAngleDegrees(e.getBearing() + (getHeading() - getRadarHeading()));
		turnGunRight(gunTurn);
		fire(3);
        if (e.getDistance() < 300){
			if (e.getBearing() > -90 && e.getBearing() <= 90){
                turnLeft(30);
				back(40);
			}
		}
        if (e.getDistance() < 100){
			if (e.getBearing() > -90 && e.getBearing() <= 90){
                turnRight(30);
				back(80);
			}
		}
		scan();
	}
    public void onHitByBullet(HitByBulletEvent e){
		turnLeft(90 - e.getBearing());
        double coinflip = Math.random();
        if(coinflip > 0.5){ahead(80);}
        if(coinflip < 0.5){back(80);}
	}
}
