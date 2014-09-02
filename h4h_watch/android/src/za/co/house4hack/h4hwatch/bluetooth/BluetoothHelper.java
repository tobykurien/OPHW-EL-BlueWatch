package za.co.house4hack.h4hwatch.bluetooth;

import java.util.Set;

import za.co.house4hack.h4hwatch.logic.WatchState.Item;
import za.co.house4hack.h4hwatch.logic.WatchState.OnStateChangedListener;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.util.Log;

public class BluetoothHelper {
	protected static final String WATCH_NAME_PREFIX = "HC-06";	

	// Intent request codes
	private static final int REQUEST_CONNECT_DEVICE_SECURE = 1;
	private static final int REQUEST_CONNECT_DEVICE_INSECURE = 2;
	private static final int REQUEST_ENABLE_BT = 3;
	
	// Debugging
	private static final String TAG = "bluetooth";
	private static final boolean D = true;
	
	// Member object for the chat services
	private BluetoothAdapter mBtAdapter;
	private boolean pairing = false;

	public BluetoothService mService = null;
	public static boolean mIsBound;
	
	private final Context activity;
	private BluetoothActivity listener = null;

	public interface BluetoothActivity {
		public void logMessage(String message);
		public void onStateChanged(Item thatChanged);
	}
	
	public BluetoothHelper(Context activity) {
		this.activity = activity;
		
		try {
			this.listener = (BluetoothActivity) activity;
		} catch (ClassCastException e) {
			Log.e("bt_helper", "Can't set listener", e);
			// ignore if activity doesn't implement the correct interface
			this.listener = null;
		}

		init();
	}	
	
	public BluetoothHelper(Context activity, BluetoothActivity listener) {
		this.activity = activity;
		this.listener = listener;
		
		init();
	}
	
	public void init() {
		// Get local Bluetooth adapter
		mBtAdapter = BluetoothAdapter.getDefaultAdapter();

		// If the adapter is null, then Bluetooth is not supported
		if (mBtAdapter == null) {
			if (listener != null) listener.logMessage("Bluetooth is not available");
			// finish();
			return;
		}

		if (mService == null)
			doBindService();
	}
	
	public void destroy() {
		if (mService != null)
			mService.watchState.setListener(null);

		doUnbindService();

		try {
			activity.unregisterReceiver(mReceiver);
		} catch (Exception e) {
		}
	}
	
	public void stop() {
		 //Stop the Bluetooth chat services
		 if (mService != null) mService.stopSelf();
	}
	
	private ServiceConnection mConnection = new ServiceConnection() {
		public void onServiceConnected(ComponentName className, IBinder service) {
			Log.d(TAG, "Bound to service");
			BluetoothService.LocalBinder binder = (BluetoothService.LocalBinder) service;
			mService = binder.getService();
			connectWatch(listener);
		}

		public void onServiceDisconnected(ComponentName className) {
			Log.d(TAG, "Service disconnected");
			mService = null;
		}
	};

	void doBindService() {
		// Establish a connection with the service. We use an explicit
		// class name because we want a specific service implementation that
		// we know will be running in our own process (and thus won't be
		// supporting component replacement by other applications).
		activity.bindService(new Intent(activity, BluetoothService.class), mConnection,
				Context.BIND_AUTO_CREATE);
		mIsBound = true;
	}

	void doUnbindService() {
		if (mIsBound) {
			// Detach our existing connection.
			activity.unbindService(mConnection);
			mIsBound = false;
		}
	}	
	
	public void connectDevice(final BluetoothDevice device, final boolean secure) {
		if (mService != null) {
			mService.connect(device, secure);
		} else {
			Log.d(TAG, "mService null, can't connect to " + device.getName());
		}
	}
	
	public void doDiscovery() {
		// Get the local Bluetooth adapter
		mBtAdapter = BluetoothAdapter.getDefaultAdapter();

		// If we're already discovering, stop it
		if (mBtAdapter.isDiscovering()) {
			mBtAdapter.cancelDiscovery();
		}

		// Request discover from BluetoothAdapter
		mBtAdapter.startDiscovery();
	}

	// The BroadcastReceiver that listens for discovered devices and
	// changes the title when discovery is finished
	private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			String action = intent.getAction();

			// When discovery finds a device
			if (BluetoothDevice.ACTION_FOUND.equals(action)) {
				// Get the BluetoothDevice object from the Intent
				BluetoothDevice device = intent
						.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
				// If it's already paired, skip it, because it's been listed
				// already
				if (device.getBondState() != BluetoothDevice.BOND_BONDED) {
					if (device.getName().startsWith(WATCH_NAME_PREFIX)) {
						Log.d(TAG, "Found unpaired device " + device.getName()
								+ " - " + device.getAddress());
						if (listener != null) listener.logMessage("Found device " + device.getName() + " - " + device.getAddress());
						if (listener != null) listener.logMessage("Connecting to the unpaired device...");
						connectDevice(device, false);
					}
				}
				// When discovery is finished, change the Activity title
			} else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED
					.equals(action)) {
				activity.unregisterReceiver(mReceiver);
				pairing = false;
			}
		}
	};

	public void connectWatch(final BluetoothActivity listener) {
		mService.watchState.setListener(new OnStateChangedListener() {
			@Override
			public void onStateChanged(Item thatChanged) {
				if (listener != null) listener.onStateChanged(thatChanged);
			}
		});

		// If BT is not on, request that it be enabled.
		// setupChat() will then be called during onActivityResult
		if (mBtAdapter != null && !mBtAdapter.isEnabled()) {
			Intent enableIntent = new Intent(
					BluetoothAdapter.ACTION_REQUEST_ENABLE);
			
			if (activity instanceof Activity) {
				((Activity) activity).startActivityForResult(enableIntent, REQUEST_ENABLE_BT);
			} else {
				enableIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
				activity.startActivity(enableIntent);
			}
			
			return;
		}

		// Register for broadcasts when a device is discovered
		IntentFilter filter = new IntentFilter(BluetoothDevice.ACTION_FOUND);
		activity.registerReceiver(mReceiver, filter);

		// Register for broadcasts when discovery has finished
		filter = new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
		activity.registerReceiver(mReceiver, filter);

		// Get the local Bluetooth adapter
		mBtAdapter = BluetoothAdapter.getDefaultAdapter();

		// Get a set of currently paired devices
		Set<BluetoothDevice> pairedDevices = mBtAdapter.getBondedDevices();
		for (BluetoothDevice d : pairedDevices) {
			if (d.getName().startsWith(WATCH_NAME_PREFIX)) {
				// found our device, connect to it
				Log.d(TAG,
						"Found device " + d.getName() + " - " + d.getAddress());
				if (listener != null) listener.logMessage("Found device " + d.getName() + " - " + d.getAddress());
				if (listener != null) listener.logMessage("Connecting to device...");
				connectDevice(d, true);
			}
		}
	}	
}
